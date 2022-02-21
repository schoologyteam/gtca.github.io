# by default a sprite works outside of chunks

class gg.Sprite extends gg.Visual
	raycaster: new THREE.Raycaster new THREE.Vector3, new THREE.Vector3 0,0,-1

	constructor: (props, @sprite) ->
		
		super props

		@type = 'Sprite'

		@sty = gg.loadSty @sprite.path

		@sprite.scale = 1 if not @sprite.scale?

		# @understeer = true

		@keyframe = [1,3,3,7]

		gg.Sprite::patch.call this, props

		@last = gg.delta

		@tile = ':o'
		@on = null
		# @autonomous = yes

		@pixie()

	dtor: ->

		gg.scene.remove @mesh
		gg.scene.remove @shadow if @shadow?

		@shadow = null
		
		super()
		12

	state: (o) ->

		@props.states = o

		1

	build: (solo) ->

		super solo

		gg.scene.add @shadow if @shadow?
		
		1

	pixie: ->

		@material = gg.material @sprite.path, this, @sprite.salt

		@geometry = new THREE.PlaneBufferGeometry @sprite.sprite.width * @sprite.scale, @sprite.sprite.height * @sprite.scale, 1
		@geometry.addAttribute 'uv2', new THREE.BufferAttribute @geometry.attributes.uv.array, 2 # for shadow light/ao maps

		@mesh = new THREE.Mesh @geometry, @material
		@mesh.castShadow = false
		@mesh.receiveShadow = false 
		# @mesh.frustumCulled = false
		@mesh.ggsolid = this
		
		return unless @sprite.hasShadow

		asd = new THREE.MeshBasicMaterial
			map: @sty
			color: 0x000000
			opacity: .25
			transparent: true
		
		@shadow = new THREE.Mesh @geometry, asd

		1

	pose: ->
		@mesh.position.set @props.x, @props.y, @props.z + @sprite.elevation
		@mesh.rotation.z = @props.r

		return unless @sprite.hasShadow and @shadow?
		
		@shadow.position.set @props.x+3, @props.y+-3, @props.z + 1 # @props.z + @sprite.elevation - 1
		@shadow.rotation.z = @props.r
		1

	frame: (i, y, geometry) ->
		ex = (@sprite.x / @sprite.sheet.width) or 0

		x = ex + ( 1 / ( @sprite.sheet.width / @sprite.sprite.width ) ) * i
		y = y
		w = 1 / ( @sprite.sheet.width / @sprite.sprite.width)
		h = @sprite.sprite.height / @sprite.sheet.height

		gg.posplane geometry or @geometry, 0, x, y, w, h
		[x, y, w, h]

	patch: (o) ->
		# return unless @props.net

		o.r = gg.normalize o.r if o.r? and @understeer
		
		@keyframe[0] = o.x if o.x?
		@keyframe[1] = o.y if o.y?
		@keyframe[2] = o.r if o.r?
		# @keyframe[3] = o.z if o.z?

		@curs = [@props.x, @props.y, @props.r, @props.z]

		if o.r? and @understeer

			d = o.r - @props.r

			if d < -Math.PI
				@curs[2] = -(d + gg.C.PII)
			else if d > Math.PI
				@curs[2] = gg.C.PII + gg.C.PII - d

		@last = 0
		1

	tween: ->
		@adds = [0, 0, 0, 0]

		@adds[i] = ( @keyframe[i] - @curs[i] ) * .1 for i in [0..3]

		@props.x += @adds[0]
		@props.y += @adds[1]
		@props.r += @adds[2]
		# @props.z += @adds[3]

		if @understeer
			if @props.r > gg.C.PII
				@props.r = @props.r - gg.C.PII
			else if @props.r < 0
				@props.r = gg.C.PII - @props.r

		true

	step: ->
		# return if @props.isPart? # sprites with base dont step

		@zaware()
		@raise()

		return unless @props.net
		
		@last += gg.delta

		if @last > 0.1
			@patch x:@keyframe[0], y:@keyframe[1], r:@keyframe[2], z:@keyframe[3]

		@tween()
		1

	zaware: ->

		tile = "#{Math.floor @props.x / 64},#{Math.floor @props.y / 64}"
		return unless tile isnt @tile
		@tile = tile
		
		xy = "#{Math.floor @props.x / gg.C.CHUNITS},#{Math.floor @props.y / gg.C.CHUNITS}"
		@at = gg.map.offChunks[xy]
		return unless @at?.active

		tiles = @at.tiles[@tile]
		return unless tiles? and Array.isArray tiles

		c = tiles[0]
		for v in tiles
			c = v if Math.abs(@props.z-v.raise.mean) < Math.abs(@props.z-c.raise.mean)

		@on = c

		0

	raise: ->
		return unless @on?

		if not @on.props.s? # simple surface
			@props.z = @on.raise.mean
			return

		gg.Sprite::raycaster.ray.origin.copy new THREE.Vector3 @props.x, @props.y, @props.z+5
		hit = gg.Sprite::raycaster.intersectObject @on.mesh

		@props.z = hit[0]?.point?.z+1 or @on.raise.mean

		1

class gg.SpriteClone extends gg.Visual

	constructor: (props, @sprite, @parent = null) ->
		super props

		console.warn 'Bad Parenting' if not @parent?

		@type = 'Sprite Clone'

		@fairy()
		;

	dtor: ->
		gg.scene.remove @mesh
		super()
		1

	fairy: ->
		@material = gg.material @sprite.path, this, @sprite.salt
		@mesh = new THREE.Mesh @parent.geometry, @material
		# @mesh.ggsolid = this
		1

	pose: ->
		@mesh.position.set @parent.props.x, @parent.props.y, @parent.props.z + @parent.sprite.elevation
		@mesh.rotation.z = @parent.props.r
		1

	step: ->
		1


