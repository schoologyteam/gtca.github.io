
class gg.Surface extends gg.Visual
	# @color: 0xffffff

	constructor: (props) ->
		super props

		@type = 'Surface'

		props.r = 0 if not props.r?
		props.f = 0 if not props.f?

		z = props.z*64
		@raise = z:z, tl:z, tr:z, bl:z, br:z, mean:z

		@tile = "#{Math.floor @props.x},#{Math.floor @props.y}"
		
	dtor: ->
		delete @chunk?.tiles[@tile]

		super()

		1

	build: (solo) ->
		@shape()
		@pose()

		@chunk.tiles[@tile] ?= []
		@chunk.tiles[@tile].push this

		super solo

		1

	pose: ->
		@mesh.position.set (@props.x*64)+32, (@props.y*64)+32,(@props.z*64)

		@mesh.updateMatrix()
		@mesh.updateMatrixWorld()

		1

	slope: ->
		return unless @props.s?

		for i, incline of @props.s
			continue unless incline # ! 0

			p = @geometry.attributes.position.array
			@geometry.attributes.position.needsUpdate = true

			s = 8*incline

			switch parseInt i # ! important
				when 0 # n
					@raise.tr = @raise.z+s
					@raise.tl = @raise.z+s
					p[2] = s
					p[5] = s
				when 1 # e
					@raise.tr = @raise.z+s
					@raise.br = @raise.z+s
					p[5] = s
					p[11] = s
				when 2 # s
					@raise.bl = @raise.z+s
					@raise.br = @raise.z+s
					p[8] = s
					p[11] = s
				when 3 # w
					@raise.tl = @raise.z+s
					@raise.bl = @raise.z+s
					p[2] = s
					p[8] = s

		@raise.mean = (@raise.tl+@raise.tr+@raise.bl+@raise.br)/4

		1

	shape : ->
		
		if "special/water/1.bmp" is @props.sty
			@material = gg.water

		else
			salt = if @props.s? then 'Sloped' else ''
			@material = gg.material @props.sty, this, salt, false

		@geometry = new THREE.PlaneBufferGeometry 64, 64, 1, 1

		gg.flipplane @geometry, 0, true if @props.f
		gg.rotateplane @geometry, 0, @props.r if @props.r

		@slope()
		
		@mesh = new THREE.Mesh @geometry, @material
		@mesh.castShadow = false
		@mesh.receiveShadow = true

		# @mesh.frustumCulled = false
		@mesh.matrixAutoUpdate = false
		
		@mesh.ggsolid = this # arb prop

		1