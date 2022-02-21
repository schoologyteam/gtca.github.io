### abstract
###
class gg.Man extends gg.Sprite
	shadow: new THREE.MeshPhongMaterial
		alphaMap: gg.loadSty 'nontile/man/alphamap.png'
		aoMap: gg.loadSty 'nontile/man/aomap.png'
		color: 0x000000
		opacity: .2
		transparent: true

	parts:
		# skins
		'wh': 'white'
		'zo': 'zombie'
		'ph': 'ponchohood'
		'gl': 'gloves'
		'le': 'leather'
		'su': 'surgical'
		'bl': 'black'
		
		# hairs
		'br': 'brown'
		'ba': 'bald'
		'Bl': 'blackhair'
		
		#shoes
		'lo': 'loafers'
		'sn': 'sneakers'
		'al': 'allstars'
		'dr': 'dress'
		
		# pants
		'je': 'jeans'
		'de': 'denim'
		'kh': 'khaki'

		# body
		'po': 'poncho'
		'sw': 'sweater'
		'bo': 'bomber'
		'pa': 'parka'
		'co': 'commando'
		'sh': 'shirt'
		
		# guns
		'hg': 'handgun'
		'sm': 'smg'
		'cb': 'carbine'
		'ar': 'ar'
		'sg': 'shotgun'
		'dm': 'dmr'
		'sp': 'sniper'

	constructor: (props) ->

		n = 667 / 29
		f = 1 / n
		
		m = .11

		sprite =
			elevation: 3
			path: 'nontile/man/template.png'
			normalPath: 'nontile/man/normal.png'
			normal: true
			hasShadow: true
			sprite:
				width: 29
				height: 29
			sheet:
				width: 261
				height: 667

		super props, sprite

		@other =		frames: 8, moment:.08,y: f * --n
		@walk =			frames: 8, moment: m, y: f * --n
		@run =			frames: 8, moment:.08,y: f * --n
		@punch =		frames: 8, moment: m, y: f * --n
		@walkpunch =	frames: 8, moment: m, y: f * --n
		@runpunch =		frames: 8, moment:.08,y: f * --n
		@slash =		frames: 8, moment: m, y: f * --n, inverse: true, start: 3
		@walkslash =	frames: 8, moment: m, y: f * --n, inverse: true, start: 3
		@runslash =		frames: 8, moment:.08,y: f * --n, inverse: true, start: 3
		@walkgun =		frames: 8, moment: m, y: f * --n
		@rungun =		frames: 8, moment:.08,y: f * --n
		@walkrifle =	frames: 8, moment: m, y: f * --n
		@runrifle =		frames: 8, moment:.08,y: f * --n
		@falls = 							  y: f * --n
		@scratch =		frames: 8, moment:.14,y: f * --n
		@jump =			frames: 8, moment:m  ,y: f * --n
		@door =			frames: 8, moment:.14,y: f * --n
		@sit =			frames: 5, moment:m  ,y: f * --n
		@drop =			frames: 8, moment:m  ,y: f * --n
		@trip1 =		frames: 9, moment:m  ,y: f * --n
		@trip2 =		frames: 8, moment:m  ,y: f * --n
		@drown =		frames: 8, moment:m  ,y: f * --n
		@cardoor =		frames: 8, moment:.13,y: f * --n, start: 2

		
		@understeer = true

		@type = 'Man'

		@build()


		@car = null
		@dead = false
		@freeze = false

		@_MAN =
			freeze: false
			moving: false
			turning: false
			_cd: null
			_yc: null
			car: null
			using: null
			strafing: false
			gallop: false
			holding: false
			recoiling: 0
			opening: false
			sitting: false
			scratching: false

		@parts = []

		# @dressup() if props.states?.o
		
		gg.clonemanmaterial this

		@shadow.material = gg.Man::shadow

		@state props, true

		@embody() # if not props.states?.d

		@grubble()

		;

	dtor: ->
		gg.world.DestroyBody @dynamicBody if @dynamicBody
		
		super()

		1

	# override
	embody: ->
		@bodyDef = new box2d.b2BodyDef()
		@bodyDef.type = box2d.b2BodyType.b2_dynamicBody
		@bodyDef.allowSleep = false

		@circleShape = new box2d.b2CircleShape 4.1 / gg.scaling

		@fixtureDef = new box2d.b2FixtureDef
		@fixtureDef.shape = @circleShape
		@fixtureDef.density = 1
		@fixtureDef.filter.categoryBits = gg.masks.organic
		@fixtureDef.filter.maskBits = gg.masks.solid | gg.masks.organic

		@bodyDef.position.Set @props.x / gg.scaling, @props.y / gg.scaling
		
		@dynamicBody = gg.world.CreateBody @bodyDef
		@dynamicBody.SetTransform @dynamicBody.GetPosition(), @props.r
		@fixture = @dynamicBody.CreateFixture @fixtureDef
		true

	present: (bool) -> # like a premature dtor
		bool = true unless bool?
		@mesh.visible = bool
		@shadow.visible = bool
		
		# part.mesh.visible = bool for part in @parts # out
		# @gun.shadow.visible = bool

		@frame 0, @other.y
		1

	dressup: (o) ->
		return if o == @oldoutfit

		console.log o if this is gg.ply

		base = JSON.parse JSON.stringify @sprite
		base.hasShadow = false

		parts = o or @props.states?.o or 'susnjepoph'

		for i in [0..4]
			s = gg.Man::parts[parts.substring i*2, i*2+2]
			@parts.push "nontile/man/#{s}.png"

		@parts.push 'nontile/man/empty.png'

		@skin = @parts[0]
		@feet = @parts[1]
		@legs = @parts[2]
		@body = @parts[3]
		@hair = @parts[4]
		@gun = @parts[5]

		@material.uniforms.skin.value = gg.loadSty @skin
		@material.uniforms.feet.value = gg.loadSty @feet
		@material.uniforms.legs.value = gg.loadSty @legs
		@material.uniforms.body.value = gg.loadSty @body
		@material.uniforms.hair.value = gg.loadSty @hair
		@material.uniforms.gun.value = gg.loadSty @gun

		# @material.uniforms.armed.value = false

		@oldoutfit = parts

		1

	# override
	patch: (o) ->
		super o
		@state o
		true

	# override
	frame: (i, y, geometry) ->
		a = super i, y, geometry

		1

	# override
	pose: ->
		super()
		1

	# override
	step: ->
		super()

		if @dead
			@pose()
			return

		if @props.net
			if @r >= gg.C.PII
				@r = @r - gg.C.PII
			else if @r <= 0
				@r = gg.C.PII - @r

			if @dynamicBody?
				@dynamicBody.SetPosition new box2d.b2Vec2 @props.x / gg.scaling, @props.y / gg.scaling
				@dynamicBody.SetTransform @dynamicBody.GetPosition(), @props.r
				@dynamicBody.SetAngularVelocity 0
				@dynamicBody.SetLinearVelocity new box2d.b2Vec2 0, 0

			#if not @_MAN.moving
			@_MAN.moving = Math.abs(@adds[0]) > .08 or Math.abs(@adds[1]) > .08

		@animate()

		@pose()

		1

	state: (o, first = false) ->
		# super o

		return unless o.states?

		STATE = o.states
		
		if STATE.o? # outfit
			@dressup STATE.o

		if STATE.scratch?
			console.log 'scratch head'
			@_MAN.scratching = true
			gg.anim.call @scratch, true

		if STATE.yc?
			car = gg.net.visuals[ STATE.yc.i ]
			@_MAN._yc = STATE.yc
			@_MAN.car = car or null
			@_MAN.opening = true
			@freeze = true
			console.log 'yc your car', STATE.yc

		if STATE.cd? # comes with .yc
			@_MAN._cd = STATE.cd

		if STATE.w?
			# console.log STATE.w
			walking = 1 is STATE.w
			running = 2 is STATE.w

			@_MAN.gallop = running
			@_MAN.moving = walking or running
			# console.log "gallop ", @_MAN.gallop

		###if STATE.b?
			has = !! STATE.b
			console.log 'man has briefcase'
			if has
				base = JSON.parse JSON.stringify @sprite
				base.hasShadow = false
				briefcase = JSON.parse JSON.stringify base
				briefcase.path = "nontile/man/briefcase.png"
				briefcase.hasShadow = true
				@briefcase = new gg.Sprite @props, gun
				@parts.push @briefcase
				@briefcase.build()
			else
				i = @parts.indexOf @briefcase
				@parts.splice i, 1
				@briefcase.dtor()###

		if STATE.u? # using
			# console.log 'using'
			@_MAN.using = STATE.u
			@hold gg.weps[ @_MAN.using ] or null

		###if STATE.outlaw?
			bandit = gg.loadSty "nontile/mobs/poncho.png"
			@sprite.skin = bandit
			@material.map = bandit
			@shadowMaterial.map = bandit###

		if STATE.r? # rrre? duno
			console.log 'r'
			gg.play gg.sounds.kungfu[ 2 ], this

		if STATE.d?
			@dead = true
			@frame 4, @falls.y
			@sprite.elevation = 1
			@shadow.visible = false

			gg.world.DestroyBody @dynamicBody if @dynamicBody?
			@dynamicBody = null

			if not first
				gg.play gg.sounds.screams[ STATE.d ], this

		if STATE.h?
			console.log 'hit'
			gg.play gg.sounds.kungfu[ STATE.h ], this

		if STATE.g?
			@_MAN.recoiling = 1
			gg.anim.call @other, true
			gg.play gg.sounds[ @_MAN.using ], this, 100

		if STATE.s?
			console.log 'slash'
			@_MAN.slashing = 1
			gg.anim.call @slash, true
			gg.anim.call @walkslash, true
			gg.anim.call @runslash, true

		if STATE.a? and not STATE.d?
			gg.play gg.sounds.hesgotagun[ STATE.a ], this

		if STATE.fall?
			@floored = STATE.fall
			@sprite.elevation = 1

			@shadow.visible = false

			gg.world.DestroyBody @dynamicBody if @dynamicBody?
			@dynamicBody = null

		if STATE.up?
			@eating = false
			@swinging = false
			@recoil = false

			@floored = null
			@falls.i = 0

			@sprite.elevation = 2

			@shadow.visible = true

			@embody()

		1

	hold: (wep) ->
		if wep?
			@_MAN.holding = switch wep.type
				when 'SMG', 'Carbine', 'Shotgun', 'AR', 'DMR', 'Sniper' 	then 'RIFLE'
				when 'Handgun' 												then 'GUN'

			@gun = "nontile/man/#{wep.type.toLowerCase()}.png"

		else
			@gun = 'empty.png'

			@_MAN.holding = no

		@material.uniforms.gun.value = gg.loadSty @gun

		1

	animate: ->
		return 'freeze' if @dead

		frame = 0
		anim = null

		if @floored?
			@frame @floored, @falls.y
			return
			
		if @_MAN.opening
			door = @_MAN.car?.model.props.doors[@_MAN._cd.i or 0] # safer ?

			@sprite.elevation = 3

			flip = @_MAN._yc.f # 'right' is door?.side

			# console.log flip

			frame = 0
			anim = @door

			gg.anim.call anim
			frame = anim.i

			if anim.i is 0
				filter = @fixture.GetFilterData()
				filter.categoryBits = gg.masks.none
				filter.maskBits = gg.masks.none
				@fixture.SetFilterData filter

				@props.r = @_MAN.car.props.r if @_MAN.car?

			if anim.i is 4
				frame = 3
				gg.anim.call @sit, true
				gg.anim.call @door, true
				gg.anim.call @cardoor, true
				@_MAN.opening = false
				@_MAN.sitting = true
				@_MAN.sat = false

			car = @_MAN.car

			f = Math.abs anim.i-4
			car?.dooring @_MAN._cd.i, f unless f is 0

			if @_MAN.opening and @_MAN.opening isnt 2
				gg.play gg.sounds.cardoor[0], this
				@_MAN.opening = 2

		else if @_MAN.sitting

			flip = @_MAN._yc.f # 'right' is door?.side

			@sprite.elevation = 1

			frame = 0
			anim = @sit

			gg.anim.call anim
			frame = anim.i

			x = @_MAN._cd.xx - @props.x
			y = @_MAN._cd.yy - @props.y
			
			range = Math.hypot x, y
			angle = Math.atan2 y, x

			@props.x += Math.cos(angle) * range / anim.frames / 4
			@props.y += Math.sin(angle) * range / anim.frames / 4

			car = @_MAN.car or @car

			gg.anim.call @cardoor
			# console.log @cardoor.i

			car?.dooring @_MAN._cd.i, @cardoor.i

			if @cardoor.i is 5 and @_MAN.sitting and @_MAN.sitting isnt 2
				gg.play gg.sounds.cardoor[1], this
				@_MAN.sitting = 2

			if @cardoor.i is 5
				@present false
				# console.log 'yay'
				@car = @_MAN.car
				@freeze = false
				@_MAN.sitting = false
				gg.net.out.BLEH = 1 if this is gg.ply
				@car?.enter this
				@_MAN.car = null

		else if @_MAN.slashing
			
			frame = 0
			anim = @slash
			anim = @walkslash if not @_MAN.gallop and @_MAN.moving
			anim = @runslash if @_MAN.gallop and @_MAN.moving and not @aim

			gg.anim.call anim
			frame = anim.i

			if anim.done
				@_MAN.slashing = false
				gg.anim.call anim, true
				@walk.i = 4
				@run.i = 4
				anim = null
			else
				@slash.i = anim.i
				@slash.timer = anim.timer
				@walkslash.i = anim.i
				@walkslash.timer = anim.timer
				@runslash.i = anim.i
				@runslash.timer = anim.timer

		else if @_MAN.scratching # and (@_MAN.scratch.done? and not @_MAN.scratch.done)

			if @_MAN.moving
				anim = null
				gg.anim.call @scratch

			else
				anim = @scratch

				gg.anim.call anim, false
				frame = anim.i

				if anim.done
					anim = null
					# console.log 'end lol at '+i
					@_MAN.scratching = false
					gg.anim.call @scratch, true
					# @scratch.inverse = false
		
		# set anim to null to trigger defualts

		if not anim?
			anim = @other
			frame = 0

			if @_MAN.moving
				@_MAN.scratching = false

				if @_MAN.holding is 'GUN'
					anim = if @_MAN.gallop then @rungun else @walkgun
				else if @_MAN.holding is 'RIFLE'
					anim = if @_MAN.gallop then @runrifle else @walkrifle
				else
					anim = if @_MAN.gallop then @run else @walk

				gg.anim.call anim
				frame = anim.i

			else if @_MAN.holding is 'GUN'
				frame = 1
			else if @_MAN.holding is 'RIFLE'
				frame = 4

			if not @_MAN.moving
				gg.anim.call @walk, true
				gg.anim.call @run, true

				if @_MAN.recoiling

					gg.anim.call @other

					if anim.i is 2
						@_MAN.recoiling = 0
					else
						frame += 1 + anim.i
				else
					gg.anim.call @other, yes


		@frame frame, anim.y

		if flip
			gg.flipplane @geometry, 0

		0

	grubble: ->

		# console.log 'lol'

		1