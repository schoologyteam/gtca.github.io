styles =
	'Ol\' Factory':
		sty: 'interior/woody/902.bmp'

	'Vault':
		corner: 	'metal/green/359b.bmp'
		rotates: yes
		middle: 	'metal/green/358.bmp'
		left: 		'metal/green/381.bmp'
		right: 		'metal/green/381.bmp'
		front: 		'metal/green/381.bmp' # 'metal/green/376.bmp'
		back: 		'metal/green/381.bmp' # 'metal/green/376.bmp'
		foundation: 'floors/green/645.bmp'
		wall: 		'metal/green/381.bmp'

	'Hall':
		corner: 	'interior/hall/346.bmp'
		rotates: no
		middle: 	'interior/hall/346.bmp'
		left: 		'interior/hall/346.bmp'
		right: 		'interior/hall/346.bmp'
		front: 		'interior/hall/346.bmp'
		back: 		'interior/hall/346.bmp'
		foundation: 'interior/hall/346.bmp'
		wall: 		'interior/hall/346.bmp'

	'Lounge':
		shininess: 30
		sty: 'interior/lounge/sty.bmp'
		rotates: no

class gg.Interior
	constructor: (@name, @style) ->
		@hidden = []

		@visuals = []
		@floors = []
		@walls = []
		@doors = []
		@intrblocks = []

		@style = styles[@style]

		for c in gg.map.actives
			for v in c.visuals
				continue unless v.vjson?
				
				#if v.type is 'Door' and v.vjson.to is @name
					#@doors.push v
					#v.pose true

				if v.type is 'Block' and v.vjson.of is @name # :)
					v.props.hide = true
					@hidden.push v

					if v.vjson.floor is 0
						n =
							type: 'Surface'
							chunk: c
							shininess: @style.shininess or 0
							interior: @name
							# vjson: "{\"of\":\"#{@name}\"}"
							# sty: 'metal/green/359.bmp'
							x: v.props.x
							y: v.props.y
							z: v.props.z

						@floors.push n

						# c.addr n

						# foundation for see-through floors
						n =
							type: 'Surface'
							# vjson: "{\"of\":\"#{@name}\"}"
							# interior: yes
							# sty: 'floors/green/645.bmp'
							x: v.props.x
							y: v.props.y
							z: v.props.z-.3

						# c.addr n

						# @pieces.push n

		for r in @floors
			b =
				type: 'Block'
				# vjson: "{\"of\":\"#{@name}\"}"
				interior: @name
				x: r.x
				y: r.y
				z: r.z
				right: @style.right
				left: @style.left
				front: @style.front
				back: @style.back

			# @walls.push b
			# @visuals.push r.chunk.addr b

			for i in @floors

				if r.x is i.x and r.y is i.y+1
					delete b.back

				if r.x is i.x and r.y is i.y-1
					delete b.front

				if r.x is i.x+1 and r.y is i.y
					delete b.left

				if r.x is i.x-1 and r.y is i.y
					delete b.right

			r.sty = @style.middle or @style.sty
			r.normal = true unless @style.rotates

			@visuals.push r.chunk.addr r

			# continue unless @style.corner

			if b.left and b.front and not b.right and not b.back
				if @style.corner
					r.sty = @style.corner
					r.r = 0 if @style.rotates

				@intrblocks.push new Intrblock x: r.x-1, y: r.y, r: 0 * Math.PI
				@intrblocks.push new Intrblock x: r.x, y: r.y+1, r: 0 * Math.PI
			else if b.right and b.front and not b.left and not b.back
				if @style.corner
					r.sty = @style.corner
					r.r = 1 if @style.rotates

				@intrblocks.push new Intrblock x: r.x+1, y: r.y, r: 1 * Math.PI
				@intrblocks.push new Intrblock x: r.x, y: r.y+1, r: 1 * Math.PI
			else if b.right and b.back and not b.left and not b.front
				if @style.corner
					r.sty = @style.corner
					r.r = 2 if @style.rotates

				@intrblocks.push new Intrblock x: r.x+1, y: r.y, r: 2 * Math.PI
				@intrblocks.push new Intrblock x: r.x, y: r.y-1, r: 2 * Math.PI
			else if b.left and b.back and not b.right and not b.front
				if @style.corner
					r.sty = @style.corner
					r.r = 3 if @style.rotates

				@intrblocks.push new Intrblock x: r.x-1, y: r.y, r: 3 * Math.PI
				@intrblocks.push new Intrblock x: r.x, y: r.y-1, r: 3 * Math.PI

		;
		
	dtor: ->
		delete v.props.hide for v in @hidden
		v.chunk.removev v for v in @visuals
		b.dtor() for b in @intrblocks

		return

class Intrblock
	constructor: (props) ->
		@bf = new box2d.b2BodyDef()
		@bf.type = box2d.b2BodyType.b2_staticBody

		x = ((props.x + .5) * 64) / gg.scaling
		y = ((props.y + .5) * 64) / gg.scaling

		@bf.position.Set x, y

		@polygonShape = new box2d.b2PolygonShape
		@polygonShape.SetAsBox 32 / gg.scaling, 32 / gg.scaling

		fd = new box2d.b2FixtureDef
		fd.shape = @polygonShape
		fd.filter.categoryBits = gg.masks.intrsolid
		fd.filter.maskBits = gg.masks.introrganic

		@body = gg.world.CreateBody @bf
		@body.SetTransform @body.GetPosition(), props.r
		@fixture = @body.CreateFixture fd

	dtor: ->
		gg.world.DestroyBody @body
		true
