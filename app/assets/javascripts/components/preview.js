(function ($) {

  function startTimer(duration, display, ontimeout) {
    var timer = duration, minutes, seconds;
    var interval = setInterval(function () {
      if (--timer < 0) {
        ontimeout ? ontimeout() : null
        clearInterval(interval);
        return;
      }

      hours   = parseInt(timer / 60 / 60, 10)
      minutes = parseInt(timer / 60 % 60, 10);
      seconds = parseInt(timer % 60, 10);

      hours   = hours > 0 ? (hours   < 10 ? "0" + hours   : hours) : "";
      minutes = minutes < 10 ? "0" + minutes : minutes;
      seconds = seconds < 10 ? "0" + seconds : seconds;

      display.textContent = (hours.length > 0 ? hours + ":" : "") + minutes + ":" + seconds;
    }, 1000);
  };

  if (tag = $("#preview_expired_time_alway_unique")[0]){
    stop_time = new Date(tag.value).getTime();
    startTimer(
      (stop_time - Date.now()) / 1000,
      $('#remain-preview-time')[0],
      function(){
        $('#disable_preview_modal').modal('show');
      });
  };

}(jQuery));