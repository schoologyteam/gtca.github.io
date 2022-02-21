
class gg.Chunk
	constructor: (x, y) ->
		@id = gg.CHUNKID++
		@x = x
		@y = y
		@hash = "#{x},#{y}"

		@tiles = []
		
		###	bunch of json strings, mostly from nosj.json ###
		@raws = []
		
		### these are gg.Visual objects factoried from @raws ###
		@visuals = []

		@lights = []

		@group = new THREE.Group
		@group.matrixAutoUpdate = false

		@prefab = false

	# unused
	post: ->
		console.log 'Ch post'

		# @gays = @visuals.filter (v) -> 'Surface' is v.type or 'Block' is v.type

		0

	_preppl: (r) ->

		l = gg.visualFactory r

		l.chunk = this

		l.build no

		@lights.push l

		l

	addr: (r) ->
		@raws.push r

		if 'Light' is r.type
			@_preppl r
			return

		if @active
			return if r.hide
			v = gg.visualFactory r
			v.chunk = this
			v.build no
			@group.add v.mesh if v.mesh?
			@visuals.push v
			return v
			
		null

	removev: (v) ->
		@raws.splice @raws.indexOf(v.raw), 1

		if @active
			@visuals.splice @visuals.indexOf(v), 1
			@group.remove v.mesh
			v.dtor()
			
		1

	disappear: (deep = false) ->
		gg.scene.remove @group

		if deep
			console.log 'deep del ch'

			v.dtor() for v in @visuals

			@visuals = []
			@tiles = []

			@group.children.length = 0

			@prefab = false

		@active = false


		gg.lightmanager.checkoff l.light for l in @lights

		1

	show: (pre = false) ->

		@active = true unless pre

		if not @prefab

			for r in @raws
				continue if r.hide

				continue if r.interior and (not gg.interior? or r.interior isnt gg.interior.name)

				v = gg.visualFactory r
				v.chunk = this
				v.build no

				@group.add v.mesh if v.mesh? # and not v.props.hide

				@visuals.push v
		
			@prefab = true

		gg.scene.add @group unless pre

		if not pre
			gg.lightmanager.register l.light for l in @lights

		# console.log "this chgroup has #{@group.children.length} meshes"

		1