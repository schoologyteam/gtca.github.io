root = exports ? this

gg =
	ply: null
	x: 0
	y: 0

	DEF: {} # ?

	DEV: no

	C: # constants
		invisible: new THREE.MeshBasicMaterial visible: false
		GODMODE: off # lmao

		PII: Math.PI * 2

		CHUNKSPAN: 6
		CHUNITS: 64 * 6

		CTABLE: [
			[[-2, 2], [-1, 2], [0, 2], [1, 2], [2, 2]],
			[[-2, 1], [-1, 1], [0, 1], [1, 1], [2, 1]],
			[[-2, 0], [-1, 0], [0, 0], [1, 0], [2, 0]],
			[[-2,-1], [-1,-1], [0,-1], [1,-1], [2,-1]],
			[[-2,-2], [-1,-2], [0,-2], [1,-2], [2,-2]]
			]

		ZOOM:
			Z: 250
			INTR: 260
			MELEE: 270
			GUN: 350
			X: 800
			DEAD: 250
			PED: 300 # 375
			CAR: 500

		AROUNDS: [
			[1,0,0], [-1,0,0],
			[0,1,0], [0,-1,0],
			[0,0,1], [0,0,-1]]

	zoom: 200
	zoomoverride: 0

	entitypool: 0
	walkpool: 0
	drivepool: 0
	parkingspacepool: 0
	audio: {}
	ed: null

	materials: {}

	settings:
		hotlineCam: yes
		prefabChunks: yes
		localMaterials: no
		simpleShading: no
		fancyHeadlights: no

	delta: 0
	base: 0.016
	timestep: 1

	frame: 0
	keys: []
	fingers: []

	mouse: {} # blegh??
	mouse2d: {}
	mouse3d: new THREE.Vector3

	left: no
	right: no

	scaling: 14

	outside: 0 # sets to ambient
	ambient: 0xffffff
	intrcolor: 0xe5e5e5

	manner: {} # rt
	
	net: null
	map: null
	world: null
	ply: null
	minimap: null
	interior: null
	walks: []
	drives: []

	masks:
		none: 0x0000
		
		solid: 0x0001
		organic: 0x0002
		items: 0x0004
		casings: 0x0008

		intrsolid: 0x00016
		introrganic: 0x00032
		intritems: 0x00064
		
	# todo: ugly vars make it pretty
	mmaps: {}
	textures: {}
	water: null
	waters: []
	wtime: 0
	wspeed: 0.15 # 0.07
	wsq: 0

	EUIDS: 0
	BIDS: 0

	chunking: false

	CURCHUNK: [-999, -999] # weak mushy shit
	CHUNKID: 1

	freezeCam: false

gg.outside = gg.ambient
root.gg = gg


$(document).ready ->

	gg.DEV = !! $('DEV').length

	gg.mobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)

	document.addEventListener 'touchstart', ((e) -> 1), { passive: false }, false
	document.addEventListener 'touchend', ((e) -> 1), false
	document.addEventListener 'touchmove', ((e)-> e.preventDefault();1), {passive: false}, false

	gg.load()

	# gg.Google.plus()
	
	setTimeout "gg.connect()", 800
	true

gg.normalize = (a) ->
	#sweet = Math.PI*2
	#n = angle
	#n += sweet while n <= -sweet
	#n -= sweet while n > sweet
	n = a - 2*Math.PI*Math.floor(a/(2*Math.PI))
	n

gg.load = ->
	gg.loadsounds()
	
	gg.map = new gg.Map()
	gg.map.getNosj()
	gg.map.chunkify()
	
	gravity = new box2d.b2Vec2 0, 0
	gg.world = new box2d.b2World gravity, false

	gg.settings.hotlineCam = false if gg.ed?
	
	gg.makepan()
	
	gg.boot.call gg
	gg.prepare()
	gg.animate()

		
	true

gg.onspawn = ->

	return if @spawned

	return if gg.ed?

	quotes = [
		'"Respect is everything" ...'
		'Is that my phone ringing? ...'
		'Where am I? ...'
		'Should I check the controls? ...'
		'"I\'m just a hunk, a hunk of burning love" ...'
		# 'The city never sleeps. ...'
		'Should I do something? ...'
	]
	

	# these two funcs give it that hotline intro
	
	# gg.music()

	gg.letterbox quotes[Math.floor Math.random() * quotes.length]

	# gg.zoom = gg.C.ZOOM.PED

	@spawned = true

	1

gg.worldstep = ->
	gg.world.Step 1.0 / 60.0, 10, 8
	gg.world.ClearForces()
	true

gg.connect = ->
	gg.net = new gg.Net
	true

gg.prepare = () ->

	gg.box = new THREE.BoxBufferGeometry 64, 64, 64
	gg.rotateplane gg.box, 0, 3
	gg.rotateplane gg.box, 1, 1
	gg.rotateplane gg.box, 2, 2
	# gg.box.attributes.position.array.slice 60, 12

	gg.extraneous()

	@waters.push gg.loadSty 'special/water/'+i+'.bmp' for i in [1..12] # by 1
	@water = new THREE.MeshLambertMaterial map: gg.waters[0], color: gg.ambient

	# spawn = spawns[ Math.floor Math.random() * spawns.length ]
	gg.camera.position.x = 0
	gg.camera.position.y = 0

	gg.arrow = new gg.Arrow

	$.getJSON "play/config.json", (data) -> gg.config = data
	$.getJSON "sons/cars.json", (data) -> gg.cars = data
	$.getJSON "sons/weps.json", (data) -> gg.weps = data
	$.getJSON "sons/activators.json", (data) -> gg.activators = data
	
	for name, model of gg.cars
		model.name = name
		gg.Cars.TYPES[name] = new gg.Cars model

	new gg.Editor if !!~ @params.indexOf 'ed'
		
	gg.map.chunkCheck()
	
	# gg.minimap = new gg.Minimap # if gg.DEV and gg.DEF.minimap and not gg.nostat
	gg.inventory = new gg.Inventory
	
	# gg.hud = new gg.Hud
	new gg.Tour
	new gg.Settings
	# gg.notice = new gg.Notice

	# setTimeout ->
	# 	gg.bubble 'Hint: Review settings if performance lacks'
	# , 15000

	if gg.settings.prefabChunks
		gg.bubble "Building #{Object.keys(gg.map.offChunks).length} city chunks..."
		
		c.show yes for i,c of gg.map.offChunks


		gg.zoom = gg.C.ZOOM.PED

	1

`gg.combinations = function(n) {
	var r = [];
		for(var i = 0; i < (1 << n); i++) {
		var c = [];
		for(var j = 0; j < n; j++) {
			c.push(i & (1 << j) ? '1' : '0');  
		}
		r.push(c.join(''));
	}
	return r;  
}`

gg.extraneous = -> # boxcutter

	gg.boxes = []

	vars = gg.combinations 5

	for a in vars
		box = gg.box.clone()
		box.gg = bin: a

		gg.boxes[a] = box

		attr = box.attributes

		attr.position.needsUpdate = true
		attr.uv.needsUpdate = true
		attr.normal.needsUpdate = true

		position = 	Array.from attr.position.array
		uv = 		Array.from attr.uv.array
		normal = 	Array.from attr.normal.array

		for i in [5..0]
			cut = ! parseInt a[i]

			continue if not cut

			f = gg.C.faceNames[i]

			# console.log "cutting #{f}. a[#{i}] is #{a[i]}"

			position.splice i*12, 12
			uv.splice i*8, 8
			normal.splice i*12, 12

			attr.position.count -= 4
			attr.uv.count -= 4
			attr.normal.count -= 4

			box.groups[i].rm = yes
			# box.groups[i].gg = f
			# @materials.splice i, 1

			for g,j in box.groups
				continue unless j > i
				g.start -= 6
				# g.materialIndex -= 1

		g.gg = gg.C.faceNames[i] for g,i in box.groups
		box.groups = box.groups.filter (g) -> ! g.rm

		for g,i in box.groups
			if 'top' is g.gg
				box.gg.top = i
				break

		attr.position.array = new Float32Array position
		attr.uv.array = new Float32Array uv
		attr.normal.array = new Float32Array normal

	1

gg.quake = 0
gg.shake = () ->
	
	a = Math.random() * 360
	
	quake = @quake/2

	if @quake>0
		@quake-=0.5
	else
		@quake = 0

	@camera.position.x += quake * Math.sin a
	@camera.position.y += quake * Math.cos a

# activates stuff, then calls render

gg.animate = () ->

	# todo: thorough spring cleanup this subroutine holy shit

	requestAnimationFrame @animate.bind this # `() => gg.animate()` # @animate.bind this

	@mouseat()
	
	@delta = @clock.getDelta()

	@timestep = @delta / @base
	@timestep = 1 if @timestep > 10

	@wtime += @delta

	if @wtime >= @wspeed
		@wsq = if @wsq < 11 then @wsq + 1 else 1
		
		@water.map = @waters[@wsq]
		@wtime = 0
	
	@ed.update() if @ed?
	
	if gg.ply?
		gg.x = gg.ply.props.x
		gg.y = gg.ply.props.y

	@map.chunkCheck()

	if @keys[114] is 1
		if @minimap?
			@minimap.dtor()
			@minimap = null
		else
			@minimap = new @Minimap

	@aim = !! @right

	@pan() if @settings.hotlineCam

	@worldstep()

	@map.step()

	@zoompass()

	if gg.ply? and not @freezeCam #
		zoom = @ichBinEineBee
		zoom *= 1.5 if gg.mobile
		@camera.position.z = (zoom ? 250) + gg.ply.props.z-64
		@camera.position.x = @ply.props.x # - (@camera.position.x/.99)
		@camera.position.y = @ply.props.y

	@shake()

	@arrow.stick()

	@render()

	for k, i in @keys
		@keys[i] = 2 if k

	@frame++
	
	true

gg.ichBinEineBee = gg.zoomoverride or gg.zoom

gg.zoompass = ->
	@zoomoverride =
	if @keys[90] # z
		@C.ZOOM.Z
	else if @keys[88] and not gg.ed? # x
		@C.ZOOM.X
	else if @zoom is 0
		@zoomoverride
	else 0

	zoom = @zoomoverride or @zoom

	if @ichBinEineBee isnt zoom
		if @ichBinEineBee < zoom
			diff = zoom - @ichBinEineBee
			diff = if diff < 5 then 5 else diff
			@ichBinEineBee += diff / 20
			@ichBinEineBee = zoom if @ichBinEineBee > zoom
		else
			diff = @ichBinEineBee - zoom
			diff = if diff < 5 then 5 else diff
			@ichBinEineBee -= diff / 20
			@ichBinEineBee = zoom if @ichBinEineBee < zoom

	@ichBinEineBee = @ichBinEineBee
	
	true

class gg.Visual
	# @color: 0xffffff

	constructor: (@props) ->
		@type = 'Visual'

		@vjson = {}

		if @props.vjson?.length
			@vjson = JSON.parse @props.vjson = @props.vjson.replace /\\/g, ""

		@props.r = 0 if not @props.r?

		if not @props.interior?
			@props.interior = !! @props.states.intr if @props.states? and @props.states.intr?
		;

	dtor: ->
		gg.scene.remove @mesh if @props.net

		@mesh.ggsolid = null if @mesh?

		# @mesh = null
		# @material = null
		# @geometry = null
		0
	
	pose: ->
		if @mesh?
			@mesh.position.x = @props.x
			@mesh.position.y = @props.y
			@mesh.position.z = @props.z

			@mesh.updateMatrix()
			@mesh.updateMatrixWorld()

		111

	step: -> 0
	patch: -> 0

	build: (solo = false) ->

		return unless solo or @props.net

		return if @props.hide

		gg.scene.add @mesh

		# console.log "visual show of #{@type}"

		1

