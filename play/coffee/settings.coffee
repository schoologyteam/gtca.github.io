class gg.Settings
	instance: null

	constructor: ->
		gg.Settings::instance = this

		@link = $ '<a href="javascript:;">Settings</a><br />'
		@link.click => @build()

		$('#links').append @link

	build: ->
		gg.Tour::instance.destroy() if gg.Tour::instance?.built
		gg.Notice::instance.destroy() if gg.Notice::instance?.built

		return if @built

		@built = true

		@settings = $ '<div class="popup" id="settings"></div>'


		content = $ "<div class=\"content\">"
		content.append '<p>Most options will momentarily freeze the game.</p>'

		experimental = '' # "<span class=\"experimental\">experimental</span>"

		switches = $ '<p class="switches"></p>'
		switches.append '-Chunks'

		prefab = $ "<div class=\"switch\">cache/prefab chunks #{experimental}</div>"
		tick = $ "<div class=\"tick #{if gg.settings.prefabChunks then 'ya'}\"></div>"
		tick.click ->
			that = $(this)
			if gg.settings.prefabChunks = ! gg.settings.prefabChunks
				that.addClass 'ya'
				gg.bubble "OK...Built #{Object.keys(gg.map.offChunks).length} chunks (prefab)"
				c.show true for i,c of gg.map.offChunks

			else
				that.removeClass 'ya'
				gg.bubble 'OK...Deep deleting prefabricated chunks'
				gg.map.dtor yes

			;
		prefab.prepend tick
		#prefab.append $ "<div class=\"whatdoesitdo\">this may positively eliminate choppy chunkloading</div>"
		switches.append prefab

		localMaterials = $ "<div class=\"switch\">local materials #{experimental}</div>"
		tick = $ "<div class=\"tick #{if gg.settings.localMaterials then 'ya'}\"></div>"
		tick.click ->
			that = $(this)
			if gg.settings.localMaterials = ! gg.settings.localMaterials
				that.addClass 'ya'
				gg.bubble "OK...Each chunk reserves it own materials"
				gg.materials = {}
				gg.map.dtor yes

			else
				that.removeClass 'ya'
				gg.bubble "OK...Sharing materials"
				gg.materials = {}
				gg.map.dtor yes

			;
		localMaterials.prepend tick
		switches.append localMaterials

		switches.append '<br>-Gfx'

		hotlineCam = $ "<div class=\"switch\">hotline cam</div>"
		tick = $ "<div class=\"tick #{if gg.settings.hotlineCam then 'ya'}\"></div>"
		tick.click ->
			that = $(this)
			if gg.settings.hotlineCam = ! gg.settings.hotlineCam
				that.addClass 'ya'
				gg.camera.rotation.z = 0

			else
				that.removeClass 'ya'
				gg.camera.rotation.z = 0

			;
		hotlineCam.prepend tick
		switches.append hotlineCam

		simpleShading = $ "<div class=\"switch\">simple shading</div>"
		tick = $ "<div class=\"tick #{if gg.settings.simpleShading then 'ya'}\"></div>"
		tick.click ->
			that = $(this)
			if gg.settings.simpleShading = ! gg.settings.simpleShading
				that.addClass 'ya'
				gg.bubble 'OK'
				gg.materials = {}
				gg.map.dtor yes

			else
				that.removeClass 'ya'
				gg.bubble 'OK...Advanced shades for you (h)'
				gg.materials = {}
				gg.map.dtor yes

			;
		simpleShading.prepend tick
		switches.append simpleShading

		fancyHeadlights = $ "<div class=\"switch\">fancy headlights</div>"
		tick = $ "<div class=\"tick #{if gg.settings.fancyHeadlights then 'ya'}\"></div>"
		tick.click ->
			that = $(this)
			if gg.settings.fancyHeadlights = ! gg.settings.fancyHeadlights
				that.addClass 'ya'
				# gg.bubble 'On'
				for i, v of gg.net?.visuals
					if v.type is 'Car'
						v.lights()

				gg.materials = {}
				gg.map.dtor yes

			else
				that.removeClass 'ya'
				# gg.bubble 'fancyHeadlights off'
				gg.materials = {}
				gg.map.dtor yes

				for i, v of gg.net?.visuals
					if v.type is 'Car' and v.headlights?
						gg.scene.remove v.headlights
						gg.scene.remove v.headlights.target

			;
		fancyHeadlights.prepend tick
		switches.append fancyHeadlights

		
		@settings.append content
		@settings.append switches
			
		@leave = $ '<div class="option">close</div>'
		@leave.click => @destroy()

		@options = $ '<div class="options"></div>'
		@options.append @leave

		@settings.append @options

		$('#overlay').append @settings
		
		true

	destroy: ->
		@settings.remove()
		@built = false
		true