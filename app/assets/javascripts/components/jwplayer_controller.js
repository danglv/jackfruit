function setup_jwplayer(container, url){
	var player = jwplayer(container);
	player.setup({
	  skin: 'seven',
	  file: url,
	  image: '',
	  width: '100%',
	  height: '100%',
	  ga: {}
	});

	var first_time = true;

	player.onPlay(function(){
	  if (first_time){
	    first_time = false;
	    Spymaster.track("video", "play", player.getPlaylist()[player.getPlaylistIndex()].file)
	  }
	});

	player.onComplete(function(){
	  Spymaster.track("video", "complete", player.getPlaylist()[player.getPlaylistIndex()].file)
	});

	window.addEventListener('beforeunload', function() {
		var label = player.getPlaylist()[player.getPlaylistIndex()].file;
	  var value = Math.round(1000 * player.getPosition());
	  Spymaster.track("video", "stop", player.getPlaylist()[player.getPlaylistIndex()].file,
	  	{position: value})
	  return "Tracked";
  });

}

(function(){
	if (typeof(jw_should_load) !== 'undefined' && jw_should_load){
		setup_jwplayer(jw_video_container, jw_video_url);
	}
})()