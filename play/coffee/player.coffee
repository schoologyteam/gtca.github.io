class gg.Player extends gg.Man
	constructor: (props) ->

		super props

		@type = 'Player'

		gg.ply = this

		# gg.zoom = gg.C.ZOOM.PED

		props.net = false

		@lastSound = null
		@lastStep = 0
		@footy = false

		@LASTW = @_MAN.gallop

		# @embody()

		# console.log props

		@oldish = x:props.x, y:props.y, z:props.z, r:0

		# part.mesh.visible = false for part in @parts

	dtor: ->
		gg.ply = null if this is gg.ply
		
		super()

		1

	# override
	embody: ->
		# console.log 'ply emb'

		if @dynamicBody?
			gg.world.DestroyBody @dynamicBody
			@dynamicBody = null

		super()

		@dynamicBody.SetLinearDamping 15
		@dynamicBody.SetAngularDamping 3

		1

	# override
	patch: (o) ->
		# console.log o

		@state o
		1

	# overide
	state: (o, first = false) ->
		return unless o.states?

		super o, first

		if o.states.g?
			wep = gg.weps[ @_MAN.using ] or null
			return unless wep
			wrhbhr = switch wep.type
				when 'Handgun' then 2
				when 'SMG' then 2
				when 'Carbine' then 3
				when 'Shotgun' then 5
				when 'AR' then 4
				when 'DMR' then 5
				when 'Sniper' then 6

			gg.quake = wrhbhr

		1

	die: -> # todo, handle this with man's states.d
		gg.zoom = gg.C.ZOOM.DEAD
		@dead = true
		@shadow.visible = false
		@sprite.elevation = 1
		# part.sprite.elevation = 1 for part in @parts

		gg.play gg.sounds.screams[ Math.floor Math.random()*4 ], this

		@frame 4, @falls.y
		1

	# override
	step: ->
		super()
		0

	steps: ->
		if @dead
			@pose()
			return

		return if @car? or not @dynamicBody?

		a = gg.keys[65]
		d = gg.keys[68]
		w = gg.keys[87]
		s = gg.keys[83]

		A = a and not d
		S = s and not w
		W = w and not s
		D = d and not a

		if gg.aim
			aim = true

			pos = gg.mouse2d

			theta = Math.atan2 @props.x - pos.x, @props.y - pos.y

			r = theta # - Math.PI/2
			r += Math.PI*2 if r < 0

			r = -r

			@props.r = r unless @freeze
			gg.ply.dynamicBody.SetTransform gg.ply.dynamicBody.GetPosition(), r

		if gg.keys[16] is 1 # shift
			@_MAN.gallop = not @_MAN.gallop

			@LASTW = if @_MAN.gallop then 2 else 1
			
			gg.net.out.W = @LASTW if gg.net?

		# copy physics
		@dynamicBody.SetAngularVelocity 0
		#@dynamicBody.SetLinearVelocity new box2d.b2Vec2 0, 0

		unless @freeze
			pos = @dynamicBody.GetPosition()
			@props.x = pos.x * gg.scaling
			@props.y = pos.y * gg.scaling
			@props.r = @dynamicBody.GetAngle()

		# @pose() # we already pose at bottom

		@_MAN.moving = W or S
		@_MAN.turning = A or D

		if aim
			@_MAN.moving = true if @_MAN.moving or @_MAN.turning

			if @LASTW isnt 1
				@LASTW = 1
				gg.net?.out.W = 1

		if aim and (a or d or w or s)

			force = 40
			force *= gg.delta
			force *= 20
			#force *= 45

			angle = 0

			if A and W
				angle = Math.PI*0.75
			else if D and W
				angle = Math.PI*0.25
			else if A and S
				angle = Math.PI*1.25
			else if D and S
				angle = Math.PI*1.75

			else if A
				angle = Math.PI*1.0
			else if S
				angle = Math.PI*1.5
			else if W
				angle = Math.PI*0.5
			else if D
				angle = 0
			else
				nomove = true

			if not nomove

				x = force * Math.cos angle
				y = force * Math.sin angle

				to = new box2d.b2Vec2 x, y

				@dynamicBody.ApplyForce to, @dynamicBody.GetWorldCenter()

		if @_MAN.turning and not aim
			r = 0
			
			r = 0.1 if A and not D
			r = -0.1 if D and not A
			
			@dynamicBody.SetTransform @dynamicBody.GetPosition(), @props.r + r
			

		if @_MAN.moving and not aim
			forces = [ 40, -20 ]
			force = 0

			force = if W then forces[0] else forces[1]

			force *= gg.delta
			force *= if @_MAN.gallop then 40 else 20

			angle = @props.r - (Math.PI/2)
			
			x = force * Math.cos angle
			y = force * Math.sin angle

			to = new box2d.b2Vec2 x, y
			
			@dynamicBody.ApplyForce to, @dynamicBody.GetWorldCenter()

		###if @props.r > gg.C.PII
			@props.r = @props.r - gg.C.PII
		else if @props.r < 0
			@props.r = gg.C.PII - @props.r###

		# shooting

		gg.net.out.T = 1 if gg.net? and gg.keys[32] # trigger, space

		# 

		# @zoom = 0

		# @animate()
		# @pose()

		1