/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

// ladies and gentlemen please enjoy

λ.FILES ++;

λ.Audio = function() {
    this.init();
};

/*pu st*/ λ.Audio.make = function() {
    λ.audio = new λ.Audio();
};

λ.Audio.prototype.init = function() {
    try {
        window.AudioContext = window.AudioContext || window.webkitAudioContext;
        this.context = new AudioContext();
    } catch (e) {
        console.err('Web Audio API is not supported in this browser');
    };
};

λ.Audio.prototype.createBufferSource = function(sound, gain) {
    var bufferSource = λ.audio.context.createBufferSource();
    bufferSource.buffer = sound.buffer;
    
    var gainNode = gain || sound.gainNode || sound.group.gainNode;
    if ( gainNode ) {
        bufferSource.connect(gainNode);
        gainNode.connect(λ.audio.context.destination);
        var volume = sound._volume || sound.group._volume;
        gainNode.gain.value = volume;
    };
    
    return bufferSource;
};

λ.Audio.prototype.play = function(sound, time, gain, loop){
    
    var bufferSource = this.createBufferSource(sound, gain);
    bufferSource.connect(λ.audio.context.destination);
    bufferSource.arbprop = sound;
    bufferSource.onended = sound.cbonended;
    sound.instances.push( bufferSource );
    var t = this.context.currentTime;
    bufferSource.start( t + time || 0 );
    bufferSource.loop = loop;
};

λ.Audio.prototype.stop = function() {
    bufferSource.stop();
};

// ###

λ.Audio.Sound = function(url) {
    this.url = url;
    this.instances = [];
};

λ.Audio.Sound.prototype.cbonended = function() {
    var sound = this.arbprop;
    
    var i = sound.instances.indexOf(this);
    
    sound.instances.splice(i, 1);
    
    //if ( this.playbackState == this.FINISHED_STATE )
        //console.log('ditto')
};

λ.Audio.Sound.prototype.volume = function(f) {
    this.gainNode = context.createGain();
    this._volume = f;
};

λ.Audio.Sound.barcb = function() {
	λ.loader.bar.css('width', f+'%');
};

// ###

λ.Audio.Loader = function(sounds) {
    this.sounds = sounds;
    this.urls = [];
    for ( var i in sounds ) {
		sounds[i].group = this;
        this.urls.push(sounds[i].url); };
    this.loaded = false;
};

λ.Audio.Loader.prototype.load = function() {
    request = new XMLHttpRequest();
    request.open("GET", url, true);
    request.responseType = "arraybuffer";
    
    this.bufferLoader = new BufferLoader(
        λ.audio.context, this.urls, λ.Audio.Loader.cb
    );
        
    this.bufferLoader.arbprop = this;
    this.bufferLoader.load();
};

λ.Audio.Loader.cb = function(bufferList) {
    var group = this.arbprop;
    for ( var i in bufferList ) {
        var sound = group.sounds[i];
        λ.audio.context.decodeAudioData(bufferList[i], function(dec) {
            console.log(dec)
            sound.buffer = dec;
            sound.loaded = true;
        } );
        // sound.buffer = bufferList[i];
    };
	
    this.loaded = true;
	
    if ( group.cb ) {
        group.cb(); };
};

λ.Audio.Loader.prototype.volume = function(f) {
    this.gainNode = λ.audio.context.createGain();
    this._volume = f;
};