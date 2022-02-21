/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */


var nosj
var map = []

var minx = 9999
var maxx = -9999

var miny = 9999
var maxy = -9999

// normalizer / negative compensation
nx = 0
ny = 0

function pull() {
	$.ajaxSetup( { "async": false } )

	$.getJSON("../sons/nosj.json", function(data) {
		console.log(data)
		nosj = data
		nosj.visuals = nosj.visuals.filter(function (a) {
			bad = a.type != 'Block' && a.type != 'Surface' && a.type != 'Door';
			return !bad;
		});
	})
}

function name() {
	$('body').append('<city>- ' + nosj.mapName + '</city>')
};

function extremesY() {
	for ( var data in nosj.visuals ) {
		var a = nosj.visuals[data]

		if ( a.type != 'Block' && a.type != 'Surface' && a.type != 'Door' )
			continue

		if ( a.y < miny )
			miny = parseInt(a.y)

		if ( a.y > maxy )
			maxy = parseInt(a.y)
		
		//console.log("visual " + a.type + " " + a.x + "," + a.y)
	}


};

function extremesX() {
	for ( var data in nosj.visuals ) {
		var a = nosj.visuals[data]

		if ( a.type != 'Block' && a.type != 'Surface' && a.type != 'Door' )
			continue

		if ( a.x < minx )
			minx = parseInt(a.x)

		if ( a.x > maxx )
			maxx = parseInt(a.x)

		//console.log("visual " + a.type + " " + a.x + "," + a.y)
	}

};

function normalize() {
	console.log("min " + minx + "," + miny + " max " + maxx + "," + maxy)
	
	if ( miny < 0 )
		ny = Math.abs(miny) + 1
	//else
		//ny = maxy
	
	if ( minx < 0 )
		nx = Math.abs(minx) + 1
	//else
		//nx = maxx
	
	console.log("normalized map of " + (maxx+nx) + "x" + (maxy+ny))

	console.log("nx " + nx)
	console.log("ny " + ny)

	for ( i = 0; i < maxy+ny+1; i ++ ) {
		map[i] = []
	}
};

function fill() {
	for ( var data in nosj.visuals ) {
		var a = nosj.visuals[data]
		
		if ( a.entity )
			continue
		
		var s = ''
		
		if ( a.top ) s = a.top
		else if ( a.sty ) s = a.sty
		else if ( a.type != 'Door' ) continue
		
		var x = parseInt(a.x)+nx
		var y = parseInt(a.y)+ny
		var z = parseInt(a.z)

		if ( a.type == 'Door' )
			z = 99

		/*if ( ! map[y] || ! map[y][x] ) {
			//console.log('omg for ', map[y]);
			continue;
		}*/
		
		if ( ! map[y][x] )
			map[y][x] = []

		if ( ! map[y][x][z] )
			map[y][x][z] = []
		
		map[y][x][z].push(new Object({
				x: parseInt(a.x),
				y: parseInt(a.y),
				z: parseInt(a.z),
				nx: x,
				ny: y,
				s: s,
				r: parseInt( (a.r) ? a.r : 0 ),
				f: !! a.f,
				type: a.type,
				vjson: JSON.parse(a.vjson || null) || {}
		}))

		var lowest = 0;
		var neww = [];
		for ( var k in map[y][x] )
			if ( k < lowest )
				lowest = k;

		for ( var k in map[y][x] ) {
			var v = map[y][x][k]

			neww[k - lowest] = v

		}

		map[y][x] = neww
		//map[y][x].sort()
	}
}

function sortMap() {
	//map.sort()
}

function table() {
	e = $('<map>')
	
	//var tdd = $('map table td').css('width')
	
	//console.log("size of td is " + tdd)

	html = '<table cellspacing="0">'

	var d = 0

	for ( i = maxy+ny; i > 0; i -- ) {
		//console.log("i " + i)
		var y = map[i]
		html += '<tr>'
		for ( j = minx+nx; j < maxx+nx+1; j ++ ) {
			//console.log("j " + j)
			//console.log("ij " + i + ", " + j)
			if ( ! map[i][j] ) {
				html += '<td empty></td>'
				continue
			}
			
			html += '<td>'
			
			for ( var k in map[i][j] ) {

				for ( z in map[i][j][k] ) {	

					var t = map[i][j][k][z]
					//console.log(t)

					if ( t.type != 'Door' ) {

						var rule = ''//'background: url(../play/sty/'+t.s+');'
						rule += 'background-size: 100%;'
						var flip = ';';
						if (t.f) {
							flip = 'rotateY(' + t.f * 180 + 'deg);';
						}
						rule += '-webkit-transform: rotate(' + t.r * 90 + 'deg) ' + flip;
						rule += '-moz-transform: rotate(' + t.r * 90 + 'deg) ' + flip;
						var title = "tile " + t.x + ", " + t.y + " or " + t.nx + ", " + t.ny

						html += '<img class="fit" src="../play/sty/'+t.s+'" style="'+rule+'" title="'+title+'" />'
					}
					else {
						rule = ''
						rule += '-webkit-transform: rotate(' + t.r * 90 + 'deg) ' + flip;
						rule += '-moz-transform: rotate(' + t.r * 90 + 'deg) ' + flip;

						html += '<img src="door.png" style="'+rule+'" title="'+((t.vjson.to)?'Door to `'+t.vjson.to+'`.':'This door doesn\'t go anywhere yet.')+'" />'
					}
				}
			}
			html += '</td>'
			
			/*if ( ! p ) {
				var title = "tile " + j + ", " + i
				html += '<td empty></td>'
				continue
			}
			else {
				var image = ''
				html += '<td>'
				for ( k in p ) {
					var t = p[k]

					//console.log(o.x + ", " + o.y)
					var rule = ''
					//rule += 'background: url(../play/sty/'+o.t+');'
					//rule += 'background-size: 100%;'
					//rule += '-webkit-transform: rotate(' + t.r * 90 + 'deg);'
					//rule += '-moz-transform: rotate(' + t.r * 90 + 'deg);'
					var title = "tile " + t.x + ", " + t.y + " or " + t.nx + ", " + t.ny
					image += 'cool'
					//image += '<img src="../play/sty/'+t.t+'" style="'+rule+'" title="'+title+'">'
				}
				html += image + '</td>'
			}*/
		}
		html += '</tr>'
	}

	html += '</table>'

	e.append(html)
	
	$('body').append(e)
	
	var w = (nx + maxx) * 32  
	var h = (ny + maxy) * 32
	
	$('map table').css('width', w+'px')
	$('map table').css('height', h+'px')

}

window.onload = function() {
	pull()
	name()
	extremesY()
	extremesX()
	normalize()
	fill()
	sortMap()
	table()
}