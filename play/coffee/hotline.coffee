

gg.makepan = ->

	yaw = value: 0, period: 0

	@pan = =>

		yaw.period += 0.012 * @timestep

		if yaw.period > Math.PI * 2
			yaw.period -= Math.PI * 2

		yaw.value = 0.0002 * Math.cos yaw.period

		@camera.rotation.z += yaw.value
		0

	@pan

gg.music = ->
	# return if gg.DEV or gg.nosound

	array = gg.sounds.music

	if Array.isArray array
		sound = array[ Math.floor Math.random() * array.length ]

	buffer = gg.audio[sound]

	return unless buffer instanceof AudioBuffer

	audio = new THREE.Audio gg.listener
	audio.setBuffer buffer
	audio.autoplay = true
	audio.setVolume 0.3
	audio.play()

gg.letterbox = (quote) ->
	console.log 'gg.letterbox'

	gg.zoom = 220

	if quote
		div = $ '<div>'
		div.attr 'id', 'letterbox'

		up = $ '<div>'
		up.attr 'class', 'up'
		div.append up

		down = $ '<div>'
		down.attr 'class', 'down'
		div.append down

		text = $ '<div>'
		text.attr 'class', 'text'
		text.text quote

		down.append text

		$('#overlay').append div

		setTimeout ->
			gg.letterbox false
			1
		, 7000

	else
		$('#letterbox').remove()
		gg.zoom = gg.C.ZOOM.PED


	1