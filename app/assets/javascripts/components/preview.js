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

function let_me_preview_this_video(url){

  var modal_content = "";
  modal_content += "<div id=\"preview_lecture_modal\" class=\"modal\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"preview_lecture_modal\">";
  modal_content += "  <div class=\"modal-dialog\" role=\"document\">";
  modal_content += "    <div class=\"modal-content\" style=\"background-color: black; height: 100%;\">";
  modal_content += "      <iframe src=\"" + url + "\" style=\"width: 100%; height: 100%; border: none;\">";
  modal_content += "      <\/iframe>";
  modal_content += "    <\/div>";
  modal_content += "  <\/div>";
  modal_content += "<\/div>";

  div = document.createElement("div");
  div.innerHTML = modal_content;
  document.body.appendChild(div.firstChild);

  $('#preview_lecture_modal').modal('show');

  $('#preview_lecture_modal').on('hidden.bs.modal', function (e) {
    this.remove();
  });
}