gg.visualFactory = (props) ->
	visual =
	switch props.type
		when 'Surface' then new gg.Surface props
		when 'Block' then new gg.Block props
		# when 'Wall' then new gg.Wall props
		when 'Neon' then new gg.Neon props

		when 'Entity' then new gg.Entity props
		when 'Light' then new gg.Light props
		when 'Walk' then new gg.Walk props
		when 'Drive' then new gg.Drive props
		when 'Parking space' then new gg.ParkingSpace props
		when 'Safe Zone' then new gg.SafeZone props

		when 'Player' then new gg.Player props
		when 'Zombie' then new gg.Zombie props
		# when 'Guy' then new gg.Guy props
		when 'Man' then new gg.Man props
		when 'Car' then new gg.Car props
		when 'Decal' then new gg.Decal props
		when 'Door' then new gg.Door props
		when 'Tree' then new gg.Tree props

		when 'Table' then new gg.Activator props
		when 'Desk' then new gg.Activator props
		when 'Chair' then new gg.Activator props
		when 'Couch' then new gg.Activator props
			
		when 'Generator' then new gg.Generator props
		when 'Worklight' then new gg.Worklight props
		when 'Lab Freezer' then new gg.LabFreezer props
		when 'Vacuum Oven' then new gg.VacuumOven props
		when 'Incubator' then new gg.Incubator props
		when 'Terminal' then new gg.Terminal props
		when 'Teleporter' then new gg.Teleporter props

		when 'ATM' then new gg.ATM props
		when 'Vending Machine' then new gg.VendingMachine props

		when 'Dumpster' then new gg.Dumpster props

		when 'Pickup' then new gg.Pickup props

		else
			console.error "unknown visual type `#{props.type}`"
			visual = new gg.Visual props


	return visual


gg.mksty = (sty, app) ->

	beh = sty.split '.'
	slash = beh[0].lastIndexOf '/'

	#if beh[0].charAt(slash+1) is 'n'
	return "#{beh[0]}#{app}.#{beh[1]}"
	#else
		#return no

	0

# unused legacy func
gg.addrtochunk = (props) ->

	x = Math.floor props.x / gg.C.CHUNITS
	y = Math.floor props.y / gg.C.CHUNITS

	hash = "#{x},#{y}"

	gg.map.offChunks[hash].addr props
	#gg.scene.add f

	console.log "adding to #{x},#{y}"

	true

gg.play = (sound, v, dist) ->
	return if gg.nosound

	if Array.isArray sound
		sound = sound[ Math.floor Math.random() * sound.length ]

	buffer = gg.audio[sound]

	return unless buffer instanceof AudioBuffer

	audio = new THREE.PositionalAudio gg.listener
	# audio.panner.panningModel = 'HRTF'
	audio.setBuffer buffer
	audio.position.set v.props.x, v.props.y, v.props.z
	audio.setRefDistance dist or 30

	audio.play()
	gg.scene.add audio
	
	1

gg.distant = (sound, id, x, y) ->
	# sound.pos3d x, y, 0.5, id
	1

gg.loadSty = (file, smooth = false, key) ->
	key ?= file

	path = "play/sty/#{file}"

	if not gg.textures[key]

		THREE.TextureLoader()
		loader = new THREE.TextureLoader

		gg.textures[key] = loader.load path, (t) ->
			t.generateMipmaps = false
			# t.anisotropy = gg.maxAnisotropy

			if not smooth
				t.magFilter = THREE.NearestFilter
				t.minFilter = THREE.NearestFilter

			# t.magFilter = THREE.LinearFilter
			# t.minFilter = THREE.LinearMipMapLinearFilter

	gg.textures[key]


gg.bubble = (q, hold) ->
	@r = $('<div class="bubble">')
	@e = $('<div class="in">')

	@r.append @e
	@e.append q

	$('#bubbles').append @r
	@r.animate {'margin-top': 0, opacity:1}, 600
	
	###
	var dismiss = $('<span class="dismiss">dismiss</span>');
	dismiss.click(function(){$(this).parent().remove();});
	e.append(dismiss);
	###
	
	@slideaway = ->
		e = @e
		e.delay(7000).animate {'margin-left': -(e.width()+40), opacity:0}, 1200, ->
			$(this).remove()
		true
	
	@slideaway() if not hold

	this

gg.anim = (reset) ->

	if reset
		delete @timer
		delete @i
		delete @done
		delete @first
		return

	@done ?= false

	@timer = if @timer? then @timer + gg.delta else 0

	@i ?= @start or 0
	
	return unless @timer >= @moment
	
	if @i is @frames-1
		@done = true
		@i = -1
	else if @start? and @first and @i is @start
		@done = true
		@i = -1
	else if @i is 0
		@done = false
		@i = @frames-1 if @inverse
	
	if @inverse then @i-- else @i++

	@timer = 0

	@first ?= true

	1

gg.posplane = (geom, face, x, y, w, h) ->
	o = face*8
	# 0 1, 1 1, 0 0, 1 0
	# left top, right top, left bottom, right bottom

	#   [ x,y, x+w,y, x,y+h, x+w,y+h ]
	a = [ x,y+h, x+w,y+h, x,y, x+w,y ]

	geom.attributes.uv.array[o+i] = a[i] for i in [0..7]
	geom.attributes.uv.needsUpdate = true

	100110

gg.flipplane = (geom, face, flip, reset) ->
	o = face*8
	
	a = geom.attributes.uv.array

	flips = [[a[o+0],a[o+1], a[o+2],a[o+3], a[o+4],a[o+5], a[o+6],a[o+7]],
			[a[o+2],a[o+3], a[o+0],a[o+1], a[o+6],a[o+7], a[o+4],a[o+5]]]

	yn = if flip then 1 else 0
	
	geom.attributes.uv.array[o+i] = flips[yn][i] for i in [0..7]
	geom.attributes.uv.needsUpdate = true

	true

gg.rotateplane = (geom, face, turns) ->
	o = face*8
	# 0 1, 1 1, 0 0, 1 0
	# left top, right top, left bottom, right bottom

	a = geom.attributes.uv.array

	switch turns
		when 1
			a = [a[o+4],a[o+5], a[o+0],a[o+1], a[o+6],a[o+7], a[o+2],a[o+3]]

		when 2
			a = [a[o+6],a[o+7], a[o+4],a[o+5], a[o+2],a[o+3], a[o+0],a[o+1]]

		when 3
			a = [a[o+2],a[o+3], a[o+6],a[o+7], a[o+0],a[o+1], a[o+4],a[o+5]]

	geom.attributes.uv.array[o+i] = a[i] for i in [0..7]
	geom.attributes.uv.needsUpdate = true

	true

gg.rotateUv = (uvs, o, turns) ->
	newy = []
	newy.push null for i in [0..o-1] if o > 0
	f = o
	s = o+1

	switch turns
		when 1
			newy.push [
					{x: uvs[f][1].x, y: uvs[f][1].y},
					{x: uvs[s][1].x, y: uvs[s][1].y},
					{x: uvs[f][0].x, y: uvs[f][0].y}]
			newy.push [
					{x: uvs[s][1].x, y: uvs[s][1].y},
					{x: uvs[f][2].x, y: uvs[f][2].y},
					{x: uvs[f][0].x, y: uvs[f][0].y}]

		when 2
			newy.push [ 
					{x: uvs[s][1].x, y: uvs[s][1].y},
					{x: uvs[s][2].x, y: uvs[s][2].y},
					{x: uvs[s][0].x, y: uvs[s][0].y}]
			newy.push [
					{x: uvs[f][2].x, y: uvs[f][2].y},
					{x: uvs[f][0].x, y: uvs[f][0].y},
					{x: uvs[f][1].x, y: uvs[f][1].y}]
		
		when 3
			newy.push [
					{x: uvs[f][2].x, y: uvs[f][2].y},
					{x: uvs[f][0].x, y: uvs[f][0].y},
					{x: uvs[s][1].x, y: uvs[s][1].y}]
			newy.push [
					{x: uvs[f][0].x, y: uvs[f][0].y},
					{x: uvs[s][0].x, y: uvs[s][0].y},
					{x: uvs[s][1].x, y: uvs[s][1].y}]
		else return

	for j in [f..s]
		for i in [0..2]
			uvs[j][i].x = newy[j][i].x
			uvs[j][i].y = newy[j][i].y
		
	true

gg.flipUv = (uvs, o, flip) ->
	a = [[[0,1],[0,0],[1,1]], [[0,0],[1,0],[1,1]]]
	b = [[[1,1],[1,0],[0,1]], [[1,0],[0,0],[0,1]]]

	c = if flip then b else a

	# left top
	uvs[o][0].x = c[0][0][0]
	uvs[o][0].y = c[0][0][1]

	# left bottom
	uvs[o][1].x = c[0][1][0]
	uvs[o][1].y = c[0][1][1]

	# right top
	uvs[o][2].x = c[0][2][0]
	uvs[o][2].y = c[0][2][1]

	# left bottom
	uvs[o+1][0].x = c[1][0][0]
	uvs[o+1][0].y = c[1][0][1]

	# right bottom
	uvs[o+1][1].x = c[1][1][0]
	uvs[o+1][1].y = c[1][1][1]

	# right top
	uvs[o+1][2].x = c[1][2][0]
	uvs[o+1][2].y = c[1][2][1]

	1

gg.pivot = (point2x, point2y, deg, centerX, centerY) ->

	newX = centerX + (point2x-centerX)*Math.cos(deg) - (point2y-centerY)*Math.sin(deg)
	newY = centerY + (point2x-centerX)*Math.sin(deg) + (point2y-centerY)*Math.cos(deg)

	{x: newX, y: newY}

gg.shadeColor2 = (color, percent) ->
    f=parseInt(color.slice(1),16)
    t=if percent<0 then 0 else 255;
    p=if percent<0 then percent*-1 else percent;
    R=f>>16;
    G=f>>8&0x00FF;
    B=f&0x0000FF;
    # "#"+
    (0x1000000+(Math.round((t-R)*p)+R)*0x10000+(Math.round((t-G)*p)+G)*0x100+(Math.round((t-B)*p)+B)).toString(16).slice(1);

gg.darker = (v) ->
	color = if not v?.props.interior then gg.ambient else gg.intrcolor
	color = "##{color.toString(16)}"
	color = color.toUpperCase()
	darker = parseInt "0x#{gg.shadeColor2 color, -.1}"
	darker

increment = 0
gg.material = (sty, v, salt, lambert) ->

	salt ?= ''
	
	salt = "#{salt}Unique#{increment++}" if gg.ed?

	if v?
		if v.props.interior
			salt = "#{salt}Interior"
		# else if gg.interior?
			# salt = "#{salt}Exterior"

		salt = "#{salt}Chunk#{v.chunk.hash}" if gg.settings.localMaterials and v.chunk?

	key = "#{sty}#{salt}"
	def = gg.definitions[sty]

	normalMap = null

	# key = "same"

	if def?
		# console.log "def for #{sty}"
		normalMap = gg.loadSty def?.normalPath

	if not gg.materials[key]?

		if lambert # and gg.settings.simpleShading
			options =
				# color: if not v?.props.interior then gg.ambient else gg.intrcolor
				map: gg.loadSty sty
				transparent: !!~ sty.indexOf '.png'
				side: THREE.FrontSide

			gg.materials[key] = new THREE.MeshLambertMaterial options

		else
			options =
				# color: if not v?.props.interior then gg.ambient else gg.intrcolor
				map: gg.loadSty sty
				specularMap: gg.loadSty sty
				normalMap: normalMap
				normalScale: new THREE.Vector2 .5, .5
				shininess: 6
				transparent: !!~ sty.indexOf '.png'
				side: THREE.FrontSide
			
			#options.shininess = 10
			#options.specular = 0x646464
			#options.specularMap = options.map
			
			gg.materials[key] = new THREE.MeshPhongMaterial options

		if !!~ salt.indexOf 'Sloped'
			gg.materials[key].color = new THREE.Color gg.darker v
		

	gg.materials[key]

man =
	normalPath: 'nontile/man/normal.png'
	seeThrough: true

bug = normalPath: 'nontile/cars/bugnormal.png'
truck = normalPath: 'nontile/cars/trucknormal.png'
wellard = normalPath: 'nontile/cars/wellardnormal.png'
anistonbd4 = normalPath: 'nontile/cars/anistonbd4normal.png'

gg.definitions =
	'nontile/man/white.png': man
	'nontile/man/ponchohood.png': man
	'nontile/man/surgical.png': man
	'nontile/man/gloves.png': man
	'nontile/man/leather.png': man
	'nontile/man/black.png': man
	'nontile/man/loafers.png': man
	'nontile/man/sneakers.png': man
	'nontile/man/dress.png': man
	'nontile/man/jeans.png': man
	'nontile/man/denim.png': man
	'nontile/man/khaki.png': man
	'nontile/man/poncho.png': man
	'nontile/man/sweater.png': man
	'nontile/man/bomber.png': man
	'nontile/man/parka.png': man
	'nontile/man/commando.png': man
	'nontile/man/shirt.png': man
	'nontile/man/brown.png': man
	'nontile/man/bald.png': man
	'nontile/man/blackhair.png': man
	'nontile/man/handgun.png': man
	'nontile/man/smg.png': man
	'nontile/man/carbine.png': man
	'nontile/man/ar.png': man
	'nontile/man/shotgun.png': man
	'nontile/man/dmr.png': man
	'nontile/man/sniper.png': man
	'nontile/cars/schoolbus.png': normalPath: 'nontile/cars/schoolbusnormal.png'
	'nontile/cars/firetruck.png': normalPath: 'nontile/cars/firetrucknormal.png'
	'nontile/cars/specialagentcar.png':  normalPath: 'nontile/cars/specialagentcarnormal.png'
	'nontile/cars/landroamer.png':  normalPath: 'nontile/cars/landroamernormal.png'
	'nontile/cars/bug.png': bug
	'nontile/cars/bug_blue.png': bug
	'nontile/cars/truck.png': truck
	'nontile/cars/wellard.png': wellard
	'nontile/cars/anistonbd4.png': anistonbd4