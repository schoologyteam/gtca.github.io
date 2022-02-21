class gg.Entity extends gg.Visual
	@color: 0xffffff

	constructor: (props) ->
		super props

		@type = 'Entity'

		@cyan = false
		@grid = no
		@size = 24

	dtor: ->
		gg.scene.remove @mesh if @mesh
		super()

	step: ->
		true

	hah: ->
		true

	cube: ->
		return false if @cyan

		@cyan = true

		@material = new THREE.MeshLambertMaterial
			map: gg.loadSty 'special/ent.png'
			transparent: true
			opacity:.5
			color: @constructor.color

		@geometry = new THREE.BoxGeometry @size, @size, @size, 1, 1, 1

		@mesh = new THREE.Mesh @geometry, @material

		if @grid
			@mesh.position.x = (@props.x * 64) + 36
			@mesh.position.y = (@props.y * 64) + 36
			@mesh.position.z = (@props.z * 64) + 32
		else
			@mesh.position.x = @props.x
			@mesh.position.y = @props.y
			@mesh.position.z = @props.z
		
		@mesh.ggsolid = this # arb prop
		
		gg.map.meshes.push @mesh
		
		gg.scene.add @mesh

		true

class gg.Walk extends gg.Entity
	@color: 0x60ff82
	
	red: new THREE.LineBasicMaterial
			color: 0xcc0000
			transparent: true
			opacity: .5
			# linewidth: 2 # "threejs doc: always 1 on Windows"

	blue: new THREE.LineBasicMaterial
			color: 0x0000ff
			transparent: true
			opacity: .5
			# linewidth: 2 # "threejs doc: always 1 on Windows"

	constructor: (props) ->
		super props

		@type = 'Walk'

		@cached = null
		@lines = []

		# props.hide = not gg.ed?
		@size = 14

		gg.walks[@vjson.id] = this
		@

	step: ->
		return unless gg.ed?
		return if @cached is @props.vjson

		@cached = @props.vjson

		gg.scene.remove l for l in @lines

		@lines = []

		return unless @vjson.links?

		for i in @vjson.links
			to = gg.walks[i]
			continue if not to?
			#continue if not to.vjson.links?
			#continue if to.vjson.links.indexOf(@vjson.id) is -1
			material = @red # if to.id < @vjson.id then gg.Walk::red else gg.Walk::blue
			geometry = new THREE.Geometry
			geometry.vertices.push new THREE.Vector3 @props.x, @props.y, @props.z
			geometry.vertices.push new THREE.Vector3 to.props.x, to.props.y, to.props.z
			line = new THREE.Line geometry, material

			@lines.push line

			gg.scene.add line

		true

	dtor: ->
		gg.scene.remove l for l in @lines

		super()

	hah: ->
		true

class gg.Drive extends gg.Entity
	@color: 0x231fd2
	
	blue: new THREE.LineBasicMaterial
			color: 0xff0000
			transparent: true
			opacity: .5
			# linewidth: 2 # "threejs doc: always 1 on Windows"

	constructor: (props) ->
		super props

		@type = 'Drive'

		@cached = null
		@lines = []

		# props.hide = not gg.ed?
		@size = 18

		gg.drives[@vjson.id] = this
		@

	step: ->
		return unless gg.ed?
		return if @cached is @props.vjson

		@cached = @props.vjson

		gg.scene.remove l for l in @lines

		@lines = []

		return unless @vjson.links?

		for i in @vjson.links
			to = gg.drives[i]
			continue if not to?
			#continue if not to.vjson.links?
			#continue if to.vjson.links.indexOf(@vjson.id) is -1
			material = @blue # if to.id < @vjson.id then gg.Walk::red else gg.Walk::blue
			geometry = new THREE.Geometry
			geometry.vertices.push new THREE.Vector3 @props.x, @props.y, @props.z
			geometry.vertices.push new THREE.Vector3 to.props.x, to.props.y, to.props.z
			line = new THREE.Line geometry, material

			@lines.push line

			gg.scene.add line

		true

	dtor: ->
		gg.scene.remove l for l in @lines

		super()

	hah: ->
		true

class gg.ParkingSpace extends gg.Entity
	@color: 0x9657ff

	constructor: (props) ->
		super props

		@type = 'Parking space'

		# props.hide = not gg.ed?
		@grid = no

	step: ->
		1

	hah: ->
		1

class gg.SafeZone extends gg.Entity
	@color: 0xff606f

	constructor: (props) ->
		super props

		@type = 'Safe Zone'

		@size = 30

	step: -> 1

class gg.Arrow
	constructor: () ->
		@show = false

		@target = x: 0, y: 0

		@material = new THREE.MeshLambertMaterial
			map: gg.loadSty 'nontile/arrow.png'
			transparent: true
			opacity: 0
			side: THREE.FrontSide
			visible: false

		# @material.depthTest = false
		# @material.depthWrite = false

		@geometry = new THREE.PlaneBufferGeometry 19/2, 27/2, 1

		@mesh = new THREE.Mesh @geometry, @material
		
		gg.scene.add @mesh

	stick: ->
		return unless @material.visible

		x = @target.x - gg.camera.position.x
		y = @target.y - gg.camera.position.y
		
		range = Math.hypot x, y
		angle = Math.atan2 y, x

		x = Math.cos(angle) * 48
		y = Math.sin(angle) * 48

		if range < 48
			@material.opacity = 0
		else
			@material.opacity = 1

		@mesh.position.set gg.camera.position.x+x, gg.camera.position.y+y, 64.05
		@mesh.rotation.z = angle - Math.PI/2

		true

	pointat: (xy) ->
		@target.x = xy.x
		@target.y = xy.y
		true