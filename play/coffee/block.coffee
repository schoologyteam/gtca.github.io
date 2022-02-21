gg.C.faceNames = ['right','left','front','back','top','bottom']
gg.C.faceNamesOpposite = [ 'left', 'right', 'back', 'front', 'bottom', 'top' ]
gg.C.rotateNames = ['rright','rleft','rfront','rback','rtop','rbottom']

gg.C.faces = 0:0,1:0, 2:1,3:1, 4:2,5:2, 6:3,7:3, 8:4,9:4

class gg.Block extends gg.Visual
	# @color: 0xffffff

	constructor: (props) ->
		super props

		@type = 'Block'

		props.r = 0 if not props.r?
		props.f = 0 if not props.f?

		@top = 4

		z = (props.z+1)*64
		@raise = z:z, tl:z, tr:z, bl:z, br:z, mean:z

		@tile = "#{Math.floor @props.x},#{Math.floor @props.y}"		

	dtor: ->
		delete @chunk?.tiles[@tile]
		
		gg.world.DestroyBody @body if @body?

		super()
		1

	build: (solo) ->
		console.log "block build"

		@shape()
		@pose()

		@chunk.tiles[@tile] ?= []
		@chunk.tiles[@tile].push this

		super solo

		1

	pose: ->
		x = (@props.x * 64)+32
		y = (@props.y * 64)+32
		z = (@props.z * 64)+32

		if @mesh
			@mesh.position.x = x
			@mesh.position.y = y
			@mesh.position.z = z

		@mesh.updateMatrix()
		@mesh.updateMatrixWorld()

		@embody() if not @body and @props.z is 1
		true

	shape: ->
		@makematerials()
		
		if @props.s? or @props.w? or gg.ed?
			@geometry = gg.box.clone()

			# @top = 4

		else if not gg.ed?
			bin = ''
			for i in [0..4]
				bin += if @props[gg.C.faceNames[i]]? then '1' else '0'

			@bin = bin = bin.toString().replace /[\s,]/g, ''

			box = gg.boxes["#{bin}"]

			@top = box.gg.top

			@geometry = box.clone()

		gg.flipplane @geometry, @top, true if @props.f
		gg.rotateplane @geometry, @top, @props.r if @props.r

		@slope()
		@wedge()

		@material = @materials

		@mesh = new THREE.Mesh @geometry, @material
		@mesh.castShadow = true
		@mesh.receiveShadow = false
		# @mesh.frustumCulled = false
		@mesh.matrixAutoUpdate = false

		gg.block = this

		@mesh.ggsolid = this # arb prop

		1

	slope: ->
		return unless @props.s?

		# console.log @geometry.attributes.position.array

		for i, incline of @props.s
			continue unless incline # ! 0

			p = @geometry.attributes.position.array
			@geometry.attributes.position.needsUpdate = true

			s = 32 + (8*incline)

			# console.log "incline to #{s}"

			switch parseInt i # ! important
				when 0 # n
					@raise.tl = @raise.z+s
					@raise.tr = @raise.z+s
					p[2] = s # tr of right
					p[17] = s # tl of left
					p[32] = s # tl of front
					p[35] = s # tr of front
					p[50] = s # tl of top
					p[53] = s # tr of top
					
				when 1 # e
					@raise.tr = @raise.z+s
					@raise.br = @raise.z+s
					p[35] = s # tr of front
					p[41] = s # br of back
					p[2] = s # tr of right
					p[8] = s # br of right
					p[53] = s # tr of top
					p[59] = s # br of top

				when 2 # s
					@raise.bl = @raise.z+s
					@raise.br = @raise.z+s
					p[8] = s # br of right
					p[23] = s # bl of left
					p[38] = s # bl of back
					p[41] = s # br of back
					p[59] = s # br of top
					p[56] = s # bl of top

				when 3 # w
					@raise.tl = @raise.z+s
					@raise.bl = @raise.z+s
					p[32] = s # tl of front
					p[38] = s # bl of back
					p[17] = s # tl of left
					p[23] = s # bl of left
					p[50] = s # tl of top
					p[56] = s # bl of top

		@raise.mean = (@raise.tl+@raise.tr+@raise.bl+@raise.br)/4

		1

	wedge: ->
		return unless @props.w?

		# console.log @geometry.attributes.position.array

		for i, doit of @props.w
			continue unless doit # ! 0

			p = @geometry.attributes.position.array
			@geometry.attributes.position.needsUpdate = true

			w = 32

			# 0:0,1:0,  2:1,3:1,  4:2,5:2,  6:3,7:3,  8:4,9:4
			# 0			1		2		3		4		5
			# 'right', 'left', 'front', 'back', 'top', 'bottom'
			switch parseInt i # ! important
				when 0 # ne
					p[0] = -32 # tr of right
					p[3] = -32 # tr-1 of right
					p[33] = -32 # tr of front
					p[27] = -32 # tr-1 of front
					p[51] = -32 # tr of top
					
				when 1 # se
					p[6] = -32 # br of right
					p[9] = -32 # br-1 of right
					p[39] = -32 # br of back
					p[45] = -32 # br-1 of back
					p[57] = -32 # br of top

				when 2 # sw
					p[18] = 32 # bl-1 of left
					p[21] = 32 # bl of left
					p[36] = 32 # bl of back
					p[42] = 32 # bl-1 of back
					p[54] = 32 # bl of top

				when 3 # nw
					;


		1
	
	makematerials: ->		
		@materials = []
		
		for f, i in gg.C.faceNames
			if @props[f]?

				if i is 4 # top
					salt = if @props.s? then 'Sloped' else ''
					@materials[i] = gg.material @props[f], this, salt, true
				else
					@materials[i] = gg.material @props[f], this, 'Lamb', true

			else
				@materials[i] = if not gg.ed? then gg.C.invisible else gg.material 'special/null/null.bmp'
				# @materials[i] = gg.material 'special/null/null.bmp'
				# m.visible = false

		true

	step: ->

		1

	embody: ->
		return if @props.interior

		@bodyDef = new box2d.b2BodyDef()
		@bodyDef.type = box2d.b2BodyType.b2_staticBody

		x = ((@props.x + .5) * 64) / gg.scaling
		y = ((@props.y + .5) * 64) / gg.scaling

		@bodyDef.position.Set x, y

		@polygonShape = new box2d.b2PolygonShape
		@polygonShape.SetAsBox 32 / gg.scaling, 32 / gg.scaling

		@fixtureDef = new box2d.b2FixtureDef
		@fixtureDef.shape = @polygonShape
		@fixtureDef.filter.categoryBits = gg.masks.solid
		@fixtureDef.filter.maskBits = -1

		@body = gg.world.CreateBody @bodyDef
		@body.CreateFixture @fixtureDef
		true