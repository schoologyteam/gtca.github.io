rotations = [[0, 1], [1, 0], [0, -1], [-1, 0]]
neons =
	'Gunstore A':
		sty: 'gunstore'
		depth: 32
		width: 256
		height: 32

	'Centre Hotel':
		sty: 'centre hotel'
		depth: 28
		width: 256
		height: 32

class gg.Neon extends gg.Visual
	constructor: (props) ->
		super props

		@type = 'Neon'

		@model = neons[@vjson.neon]
		
		gg.neon = this # debug

		@width = @vjson.width or 64
		@height = @vjson.height or 3
		@depth = @vjson.depth or 16

		@timer = 0
		@pixel = 0

		return if gg.interior? and gg.interior.name is @vjson.hiddenfor

		@shape()
		@board() if @model?
		
		@pose()

	build: ->
		gg.scene.add @mesh if @mesh?
		gg.scene.add @boardmesh if @boardmesh?
		true

	dtor: ->
		gg.scene.remove @mesh if @mesh?
		gg.scene.remove @boardmesh if @boardmesh?
		true

	step: ->
		return unless @mesh? and @model?

		@timer += gg.delta

		if @timer > .07
			@timer = 0
			@pixel += 1
			@pixel -= @model.width if @pixel > @model.width

		x = @pixel / @model.width
		y = (1 - ((@depth / @model.height)))/2

		gg.posplane @geometry, 0, x, y, @width / @model.width, @depth / @model.height


	pose: ->
		r1 = rotations[@props.r][0]
		r2 = rotations[@props.r][1]

		@mesh.position.x = (@props.x * 64) + 32 + r1*(64-@height)/2
		@mesh.position.y = (@props.y * 64) + 32 + r2*(64-@height)/2
		@mesh.position.z = (@props.z * 64) + (64-@depth)/2 + @depth/2

		@mesh.rotation.z = -(Math.PI/2)*@props.r

		return unless @boardmesh?

		@boardmesh.position.x = (@props.x * 64)+32 - (r1*@height/2) + r1*(64-@height)/2
		@boardmesh.position.y = (@props.y * 64)+32 - (r2*@height/2) + r2*(64-@height)/2
		@boardmesh.position.z = (@props.z * 64) + (64-@depth)/2 + @depth/2

		@boardmesh.rotation.x = Math.PI/2
		@boardmesh.rotation.y = -(Math.PI/2)*@props.r
		true

	shape: ->
		materials = []

		for f, i in gg.C.faceNames
			materials[i] = gg.material 'metal/conveyor/310.bmp'

		materials[3].map = gg.loadSty 'misc/a/neonpixels.bmp'
		materials[3].specularMap = materials[3].map
		materials[3].specular = new THREE.Color 0xffffff
		materials[3].map.wrapT = THREE.RepeatWrapping
		materials[3].map.wrapS = THREE.RepeatWrapping

		@material = materials

		@geometry = new THREE.BoxBufferGeometry @width, @height, @depth

		gg.posplane @geometry, 4, 0, .5, @width/64, @height/64
		gg.posplane @geometry, 0, 0, .5, @height/64, @depth/64
		gg.posplane @geometry, 1, 0, .5, @height/64, @depth/64
		gg.posplane @geometry, 2, 0, .5, @width/64, @depth/64
		gg.posplane @geometry, 3, 0, .5, @width/64, @depth/64

		gg.rotateplane @geometry, 0, 3
		gg.rotateplane @geometry, 1, 1
		gg.rotateplane @geometry, 2, 2
		
		@mesh = new THREE.Mesh @geometry, @material
		
		@mesh.ggsolid = this # arb prop

		1

	board: ->
		map = gg.loadSty "nontile/neons/#{@model.sty}.png"
		map.wrapT = THREE.RepeatWrapping
		map.wrapS = THREE.RepeatWrapping
		
		board = gg.material "nontile/neons/#{@model.sty}.png"

		@geometry = new THREE.PlaneBufferGeometry @width, @depth, 1
		@boardmesh = new THREE.Mesh @geometry, board

		1