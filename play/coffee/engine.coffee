$(document).mousemove (event) ->
	gg.mouse =
		x: event.clientX
		y: event.clientY

	gg.ed.mousing() if gg.ed?

	return

gg.mouseat = ->
	vector = new THREE.Vector3

	@mouse3d = new THREE.Vector3(
		( gg.mouse.x / window.innerWidth ) * 2 - 1,
		- ( gg.mouse.y / window.innerHeight ) * 2 + 1,
		0.5 )

	vector = @mouse3d.clone()

	vector.unproject gg.camera 

	dir = vector.sub( gg.camera.position ).normalize()

	distance = - gg.camera.position.z / dir.z

	pos = gg.camera.position.clone().add( dir.multiplyScalar(distance) )

	@mouse2d = pos

	1

$(document).mouseup (event) ->
	gg.left = 0 if event.button is 0
	gg.right = 0 if event.button is 2

	return

$(document).mousedown (event) ->
	gg.left = 1 if event.button is 0
	gg.right = 1 if event.button is 2

	gg.ed.click() if gg.ed?

	return

$(document).on 'contextmenu', -> false


document.onkeydown = document.onkeyup = (event) ->
	k = event.keyCode

	if event.type is 'keydown' and gg.keys[k] isnt 2
		gg.keys[k] = 1
	else if event.type is 'keyup'
		gg.keys[k] = 0

	if not gg.keys[ k ]
		delete gg.keys[k]

	if k is 114
		event.preventDefault()
	
	# console.log gg.keys

	gg.ed.key() if gg.ed?

	1

gg.clonemanmaterial = (man) ->

	material = @manMaterial.clone()

	man.material = material

	man.mesh.material = material

	material.map = gg.loadSty 'nontile/man/template.png'
	material.color = new THREE.Color 0xffffff
	material.specular = new THREE.Color 0x111111
	material.shininess = 10
	material.opacity = 1.0

	material.program = @manMaterial.program

	material.uniforms.soft.value = material.map

	material.uniforms.skin.value = material.map
	material.uniforms.feet.value = material.map
	material.uniforms.legs.value = material.map
	material.uniforms.body.value = material.map
	material.uniforms.hair.value = material.map

	material.uniforms.map.value = material.map

	material.uniforms.diffuse.value = material.color
	material.uniforms.specular.value = material.specular
	material.uniforms.shininess.value = Math.max material.shininess, 1e-4
	material.uniforms.opacity.value = material.opacity

	gg.softfor man, 'nontile/man/template.png'

	1

gg.clonecarmaterial = (car) ->

	material = @carMaterial.clone()

	car.material = material

	car.mesh.material = material

	material.map = gg.loadSty car.path
	material.color = new THREE.Color 0xffffff
	material.specular = new THREE.Color 0x111111
	material.shininess = 10
	material.opacity = 1.0

	material.uniforms.soft.value = material.map

	material.uniforms.map.value = material.map

	###material.uniforms.diffuse.value = material.color
	material.uniforms.specular.value = material.specular
	material.uniforms.shininess.value = Math.max material.shininess, 1e-4
	material.uniforms.opacity.value = material.opacity###

	gg.softfor car, car.path

	1

gg.softs = []

sets = []

gg.softfor = (v, file) ->
	
	url = "play/sty/#{file}"

	gg.softs[ url ] ?= new THREE.Texture

	texture = gg.softs[ url ]

	v.material.uniforms.soft.value = texture
	v.material.uniforms.soft.needsUpdate = true

	return if texture.aye

	texture.aye = true

	image = new Image
	image.src = url

	image.onload = ->
		# console.log 'softfor image onload'

		canvas = gg.canvas.get 0
		
		canvas.width = this.width
		canvas.height = this.height

		context = canvas.getContext "2d"

		context.drawImage image, 0, 0

		StackBlur.canvasRGBA canvas, 0, 0, this.width, this.height, 2
		data = context.getImageData 0, 0, this.width, this.height

		image = new Image
		image.src = canvas.toDataURL()

		texture.image = image

		texture.needsUpdate = true
		texture.minFilter = THREE.LinearFilter

		0

	0

gg.createsoftcanvas = ->
	@canvas = $('<canvas/>', { id: 'resizer' });

	@canvas.css 'display', 'none'
	@canvas.css 'position', 'absolute'
	@canvas.css 'left', 0
	@canvas.css 'top', 0

	$(document.body).append @canvas

	1

gg.custommaterials = ->

	# links / custom phong based material:

	# https://github.com/Jam3/glsl-fast-gaussian-blur/blob/master/5.glsl (soft ao glow)
	# https://github.com/mrdoob/three.js/blob/bde8a0540d1b6a7f0a9daf66f00e8f160994ff93/examples/webgl_gpgpu_water.html#L354 (shadermaterial with phong uniforms)
	# https://github.com/mrdoob/three.js/issues/2534 (cloning)

	# todo: add new shaderid?
	# https://github.com/mrdoob/three.js/blob/35a26f178c523514673d992da1aece23c1cfca6e/src/renderers/webgl/WebGLPrograms.js#L12

	# material: make a ShaderMaterial clone of MeshPhongMaterial, with customized vertex shader
	material = @manMaterial = new THREE.ShaderMaterial
		uniforms: THREE.UniformsUtils.merge( [
			THREE.ShaderLib[ 'phong' ].uniforms,
			{
				soft: { value: null }

				skin: { value: null }
				feet: { value: null }
				legs: { value: null }
				body: { value: null }
				hair: { value: null }
				gun: { value: null }

				# armed: { value: false }
			}
		] )
		defines: 'MAN': ''
		transparent: true
		lights: true
		fog: true
		vertexShader: THREE.ShaderChunk[ 'meshphong_vert' ]
		fragmentShader: document.getElementById( 'fairyFragmentShader' ).textContent

	material.map = gg.loadSty 'nontile/man/template.png'

	material.uniforms.soft.value = material.map

	material.uniforms.skin.value = material.map
	material.uniforms.feet.value = material.map
	material.uniforms.legs.value = material.map
	material.uniforms.body.value = material.map
	material.uniforms.hair.value = material.map
	material.uniforms.gun.value = material.map

	material.uniforms.map.value = material.map

	material.uniforms.diffuse.value = material.color
	material.uniforms.specular.value = material.specular
	material.uniforms.shininess.value = Math.max material.shininess, 1e-4
	material.uniforms.opacity.value = material.opacity

	# now for car

	material = @carMaterial = new THREE.ShaderMaterial
		defines: 'CAR': ''
		uniforms: THREE.UniformsUtils.merge( [
			THREE.ShaderLib[ 'phong' ].uniforms,
			{
				soft: { value: null }

				# delta1: { value: null }
				# delta2: { value: null }
			}
		] )
		transparent: true
		lights: true
		fog: true
		vertexShader: THREE.ShaderChunk[ 'meshphong_vert' ]
		fragmentShader: document.getElementById( 'fairyFragmentShader' ).textContent

	material.map = gg.loadSty 'nontile/arrow.png'

	1

gg.boot = ->

	@params = document.location.href.split('#')

	@nosound = !!~ @params.indexOf 'nosound'
	@nostat = !!~ @params.indexOf 'nostat'

	# gg.play gg.sounds.andremember[0]
	
	container = document.getElementById 'container'

	@camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 1500)
	
	@raycaster = new THREE.Raycaster

	@camera.position.z = @zoomoverride or @zoom
	@camera.position.x = 0
	@camera.position.y = 0
	
	@clock = new THREE.Clock()
	@scene = new THREE.Scene()

	# @scene.fog = new THREE.FogExp2 0xa9a9bc, 0.0015

	@ambientlight = new THREE.AmbientLight 0x757575
	@scene.add @ambientlight

	@moon = new THREE.DirectionalLight 0xa9a9bc, .3
	@moon.castShadow = false
	@moon.position.set 0, 0, 100
	@moon.target.position.set -50, -50, 0

	@moon.shadow.camera.bottom = -512
	@moon.shadow.camera.left = -512
	@moon.shadow.camera.top = 512
	@moon.shadow.camera.right = 512

	# @helper = new THREE.CameraHelper( @moon.shadow.camera );
	# @scene.add( @helper );

	@moon.shadow.mapSize.width = @moon.shadow.mapSize.height = 1024
	# @scene.add @moon
	# @scene.add @moon.target

	gg.custommaterials()

	gg.createsoftcanvas()
	
	@raycaster = new THREE.Raycaster
	
	@renderer = new THREE.WebGLRenderer # antialias: true
	@renderer.setSize window.innerWidth, window.innerHeight

	@renderer.shadowMap.enabled = false
	@renderer.shadowMap.type = THREE.PCFSoftShadowMap

	@renderer.shadowMap.autoUpdate = false
	@renderer.shadowMap.needsUpdate = true # when scene changes

	# @composer = new THREE.EffectComposer @renderer
	# @composer.setSize window.innerWidth, window.innerHeight

	# renderPass = new THREE.RenderPass @scene, @camera
	# renderPass.renderToScreen = true

	# @composer.addPass renderPass

	# http://john-chapman-graphics.blogspot.nl/2013/01/per-object-motion-blur.html

	hearing.call gg

	@maxAnisotropy = @renderer.capabilities.getMaxAnisotropy()
	
	#renderer.setClearColor( 0x000000, 0 );

	container.innerHTML = ""

	container.appendChild @renderer.domElement
	
	window.addEventListener 'resize', onWindowResize, false

	gg.thumbs()

	true

hearing = ->
	@listener = new THREE.AudioListener
	@listener.up = new THREE.Vector3 0, 1, 0
	@camera.add @listener
	no

gg.thumbs = ->
	return unless gg.mobile
	
	gg.bubble "<span style=\"color: orange\">Detected mobile; using experimental phone controls</span>"

	directions = $ '<div class="directions">'

	# gg.zoom = gg.C.ZOOM.PED

	up = $('<div>').text '↑'
	down = $('<div>').text '↓'
	left = $('<div>').text '←'
	right = $('<div>').text '→'
	use = $('<div>').addClass('').text 'e'
	shift = $('<div>').addClass('arbitrary').text 'shift'
	space = $('<div>').addClass('arbitrary').text 'shoot'

	does = []
	does.push j: up,	keycode: 87
	does.push j: down,	keycode: 83
	does.push j: left,	keycode: 65
	does.push j: right,	keycode: 68
	does.push j: use,	keycode: 69
	does.push j: shift,	keycode: 16
	does.push j: space,	keycode: 32

	key = (o, i, n) -> gg.keys[i] = n

	for o in does
		do (o) ->
			o.j.on
				'mousedown': (e) -> key this, o.keycode, 1
				'touchstart': (e) -> key this, o.keycode, 1
			o.j.on
				'mouseup': (e) -> key this, o.keycode, 0
				'touchend': (e) -> key this, o.keycode, 0


	span = -> $ '<span>'
	br = -> $ '<br />'

	directions.append span(), up, br(), left, down, right, br(), use, shift, space

	$('#overlay').append directions


	1


gg.render = () ->
	
	# @helper.update()

	# @composer.render()

	@renderer.render @scene, @camera

	if @ed?
		@raycaster.setFromCamera @mouse3d.clone(), @camera

	true

onWindowResize = () ->
	gg.camera.aspect = window.innerWidth / window.innerHeight

	gg.camera.updateProjectionMatrix()

	gg.renderer.setSize window.innerWidth, window.innerHeight

	true

gg.sounds =
	music: [
		'play/snd/scattle-inner-animal.mp3'
		'play/snd/scattle-its-safe-now.mp3'
	]

	andremember: [
		'play/snd/SFX_ICE_CREAM_VAN_TUNE_1.wav'
	]

	icecream: [
		'play/snd/SFX_ICE_CREAM_VAN_TUNE_1.wav'
	]

	footsteps: [
		'play/snd/SFX_FOOTSTEP_CONCRETE_1.wav'
		'play/snd/SFX_FOOTSTEP_CONCRETE_2.wav'
		'play/snd/SFX_FOOTSTEP_CONCRETE_3.wav'
		'play/snd/SFX_FOOTSTEP_CONCRETE_4.wav'
	]

	elvis: [
		'play/snd/SFX_ELVIS_1.wav'
		'play/snd/SFX_ELVIS_6.wav'
	]

	hesgotagun: [
		'play/snd/SFX_NEW_PED_DGOTGUN1.wav'
		'play/snd/SFX_NEW_PED_DGOTGUN2.wav'
		'play/snd/SFX_NEW_PED_DGOTGUN3.wav'
		# 'play/snd/SFX_NEW_PED_DGOTGUN4.wav'
	]

	cardoor: [
		'play/snd/SFX_CAR_DOOR_OPEN_1.wav'
		'play/snd/SFX_CAR_DOOR_CLOSE_1.wav'
	]

	carengine: [
		'play/snd/SFX_STANDARD_SALOON_ENGINE.wav'
		'play/snd/SFX_SPORTS_SALOON_ENGINE.wav'
		'play/snd/SFX_SUPERCAR_ENGINE.wav'
		'play/snd/SFX_VAN_ENGINE.wav'
		'play/snd/SFX_TRUCK_ENGINE.wav'
	]

	carenginestart: [
		'play/snd/SFX_STARTER_MOTOR_1.wav'
		'play/snd/SFX_STARTER_MOTOR_2.wav'
	]

	screams: [
		'play/snd/SFX_NEW_PED_DSCREAM1.wav'
		'play/snd/SFX_NEW_PED_DSCREAM2.wav'
		'play/snd/SFX_NEW_PED_DSCREAM3.wav'
		'play/snd/SFX_NEW_PED_DSCREAM4.wav'
		'play/snd/SFX_NEW_PED_DONFIRE1.wav'
		'play/snd/SFX_NEW_PED_DONFIRE2.wav'
		'play/snd/SFX_NEW_PED_DONFIRE3.wav'
		'play/snd/SFX_NEW_PED_DONFIRE4.wav'
		'play/snd/SFX_NEW_PED_DONFIRE5.wav'
		'play/snd/SFX_NEW_PED_DONFIRE6.wav'
	]

	kungfu: [
		'play/snd/SFX_PUNCH_HIT.wav'
		'play/snd/SFX_BULLET_PED.wav'
		'play/snd/SFX_COLLISION_CAR_PED_SQUASH.wav'
	]

	impacts: [
		'play/snd/SFX_BULLET_CAR_1.wav'
		'play/snd/SFX_BULLET_CAR_2.wav'
		'play/snd/SFX_BULLET_CAR_3.wav'
		'play/snd/SFX_BULLET_PROOF_CAR_1.wav'
		'play/snd/SFX_BULLET_PROOF_CAR_2.wav'
		'play/snd/SFX_BULLET_PROOF_CAR_3.wav'
		'play/snd/SFX_BULLET_WALL_1.wav'
		'play/snd/SFX_BULLET_WALL_2.wav'
		'play/snd/SFX_BULLET_WALL_3.wav'
	]

	'M9': [
		'play/snd/nongta2/M9.1.mp3'
		'play/snd/nongta2/M9.2.mp3'
	]

	'M1911': [
		'play/snd/nongta2/M1911.1.mp3'
		'play/snd/nongta2/M1911.2.mp3'
	]

	'FN 57': [
		'play/snd/nongta2/FN 57.1.mp3'
		# 'play/snd/nongta2/FN 57.2.mp3'
		'play/snd/nongta2/FN 57.3.mp3'
	]

	'Compact 45': [
		'play/snd/nongta2/Compact 45.1.mp3'
		'play/snd/nongta2/Compact 45.2.mp3'
	]

	'Desert Eagle': [
		'play/snd/nongta2/Desert Eagle.1.mp3'
		'play/snd/nongta2/Desert Eagle.2.mp3'
	]

	'.44 Magnum': [
		'play/snd/nongta2/.44 Magnum.1.mp3'
		'play/snd/nongta2/.44 Magnum.2.mp3'
	]

	'UMP': [
		# 'play/snd/nongta2/UMP.1.mp3'
		'play/snd/nongta2/UMP.2.mp3'
		# 'play/snd/nongta2/UMP.3.mp3'
		'play/snd/nongta2/UMP.4.mp3'
	]

	'UMP': [
		# 'play/snd/nongta2/UMP.1.mp3'
		'play/snd/nongta2/UMP.2.mp3'
		# 'play/snd/nongta2/UMP.3.mp3'
		'play/snd/nongta2/UMP.4.mp3'
	]

	'Groza-1': [
		# 'play/snd/nongta2/Groza-1.1.mp3'
		'play/snd/nongta2/Groza-1.2.mp3'
		'play/snd/nongta2/Groza-1.3.mp3'
	]

	'Magpul PDR': [
		'play/snd/nongta2/Magpul PDR.1.mp3' # off
		'play/snd/nongta2/Magpul PDR.2.mp3'
		'play/snd/nongta2/Magpul PDR.3.mp3'
	]

	'Groza-4': [
		'play/snd/nongta2/Groza-4.1.mp3'
		'play/snd/nongta2/Groza-4.2.mp3'
	]

	'G36C': [
		# 'play/snd/nongta2/G36C.1.mp3'
		'play/snd/nongta2/G36C.2.mp3'
		'play/snd/nongta2/G36C.3.mp3'
		# 'play/snd/nongta2/G36C.4.mp3'
	]

	'M4A1': [
		'play/snd/nongta2/M4A1.1.mp3'
		'play/snd/nongta2/M4A1.2.mp3'
	]

	'AS Val': [
		'play/snd/nongta2/AS Val.1.mp3'
		'play/snd/nongta2/AS Val.2.mp3'
	]

	'AK-12': [
		'play/snd/nongta2/AK-12.1.mp3'
		# 'play/snd/nongta2/AK-12.2.mp3'
		'play/snd/nongta2/AK-12.3.mp3'
	]

	'AEK-971': [
		'play/snd/nongta2/AEK-971.1.mp3'
		'play/snd/nongta2/AEK-971.2.mp3'
	]

	'AN-94': [
		'play/snd/nongta2/AN-94.1.mp3'
		'play/snd/nongta2/AN-94.2.mp3'
		'play/snd/nongta2/AN-94.3.mp3'
	]

	'HK416': [
		# 'play/snd/nongta2/M416.1.mp3'
		'play/snd/nongta2/M416.2.mp3'
		'play/snd/nongta2/M416.3.mp3'
	]

	'M16A4': [
		'play/snd/nongta2/M16A4.1.mp3'
		'play/snd/nongta2/M16A4.2.mp3'
	]

	'SCAR-H': [
		'play/snd/nongta2/SCAR-H.1.mp3'
		'play/snd/nongta2/SCAR-H.2.mp3'
	]

	'SPAS-12': [
		'play/snd/nongta2/SPAS-12.1.mp3'
		'play/snd/nongta2/SPAS-12.2.mp3'
	]

	'Mare\'s Leg': [
		'play/snd/nongta2/Mare\'s Leg.1.mp3'
		'play/snd/nongta2/Mare\'s Leg.2.mp3'
	]

	'SKS': [
		'play/snd/nongta2/SKS.1.mp3'
		'play/snd/nongta2/SKS.2.mp3'
	]

	'SVD-12': [
		'play/snd/nongta2/SVD-12.1.mp3'
		'play/snd/nongta2/SVD-12.2.mp3'
	]

	'Scout Elite': [
		'play/snd/nongta2/Scout Elite.1.mp3'
		# 'play/snd/nongta2/Scout Elite.2.mp3'
		'play/snd/nongta2/Scout Elite.3.mp3'
	]

	'M40A5': [
		'play/snd/nongta2/M40A5.1.mp3'
		'play/snd/nongta2/M40A5.2.mp3'
	]

	'Intervention': [
		'play/snd/nongta2/M40A5.1.mp3'
		'play/snd/nongta2/M40A5.2.mp3'
	]

soundsloaded = 0
gg.loadsounds = () ->

	for k, e of gg.sounds
		for i, v of e
			go = ->
				loader = new THREE.AudioLoader
				that = v
				loader.load that, (buffer) ->
					a = gg.audio[that] ?= buffer
					# console.log "done loading #{that}"
					return
			go()

	1