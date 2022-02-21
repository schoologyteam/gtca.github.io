rotations = [[0, 31.95], [31.95, 0], [0, -31.95], [-31.95, 0]]
intrrotations = [[0, 32.05], [32.05, 0], [0, -32.05], [-32.05, 0]]

class gg.Door extends gg.Visual
	constructor: (props) ->
		super props

		@type = 'Door'
		
		gg.door = this # debug

		@path = 'zaibatsu'

		@path = @vjson.door if @vjson.door?
		@path = "nontile/doors/#{@path}.png"

		@shape()
		
		@pose()

	build: ->
		# return if @vjson.door is 'hidden' and not gg.ed?
		
		gg.scene.add @mesh
		true

	dtor: ->
		gg.scene.remove @mesh
		true

	step: -> 0

	pose: ->
		intr = gg.interior? and @vjson.to is gg.interior.name

		r = if not intr then rotations else intrrotations

		if @vjson.door is 'hidden' and not intr
			@material.opacity = 0

		@mesh.position.x = (@props.x * 64)+32 + r[@props.r][0]
		@mesh.position.y = (@props.y * 64)+32 + r[@props.r][1]
		@mesh.position.z = (@props.z * 64)+24

		@mesh.rotation.x = Math.PI/2
		@mesh.rotation.y = -(Math.PI/2)*@props.r

		true

	shape : ->
		@material = gg.material @path

		@material.color.setHex 0x060606 if 'hidden' is @vjson.door

		@geometry = new THREE.PlaneBufferGeometry 32, 48, 1
		
		@mesh = new THREE.Mesh @geometry, @material
		
		@mesh.ggsolid = this # arb prop

		true