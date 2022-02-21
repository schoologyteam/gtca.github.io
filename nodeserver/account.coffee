class Account
	@static = no

	constructor: (@ses) ->

		;

	fetch: ->
		query = "SELECT * FROM `accounts` WHERE x >= #{@ux} AND y >= #{@uy} AND x < #{@uex} AND y < #{@uey}"

		that = this

		gta.db.query query, (err, rows) ->
			that.take rows
			return
		0

	take: (param) ->
		@data = 0
		true

module.exports = Account
