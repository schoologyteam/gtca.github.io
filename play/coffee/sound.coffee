class gg.Sound extends gg.Entity
	constructor: (props) ->

		super props

		that = this

		@shape()
		@pose()

	build: ->
		# gg.scene.add @audio
		1

	dtor: ->
		# gg.scene.remove @audio
		1

	shape: ->
		# that.audio.setBuffer buffer
		# that.audio.setRefDistance that.data.refDistance or 4
		# that.audio.setLoop that.data.loop###
		1
	pose: ->
		# @audio.position.set @props.x, @data.y, @data.z

		1

	step: ->
		@pose()
		1