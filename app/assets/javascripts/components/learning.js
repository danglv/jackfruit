$(document).ready(function (){
	$('#comment-dropdown').click(function (e){
	  	e.stopPropagation(); 
		});
	// close popup
	$('#close-send-comment').click(function (){
    $('#comment-dropdown').fadeOut(225);
		$('#comment-dropdown').removeClass('active');
	})
	// send request to add comment 
	$('#send-comment').click(function (){

		var course_id = $("#course-id").val();
  	var _title = $("#comment-title").val();
  	var _description = $("#comment-content").val();
  	if(_title.trim() == ''){
  		$("#comment-title").focus();
  		return;
  	}
  	if(_description == ''){
  		$("#comment-content").focus();
  		return;
  	}
  	var params = {
  		'title' : _title,
  		'description' : _description
  	}
		var URL = 'http://' + window.location.host + '/courses/' + course_id + '/add_discussion';
		$.ajax({
		    type: 'POST',
		    url: URL,
		    data: params,
		    success: function(msg){
		      var respon =$.parseJSON(JSON.stringify(msg));
		      var comment_item = '<div class="col s12 no-padding cm-item"> <div class="row cm-item-header no-margin"> <ul class="no-margin"> <li> <i class="small material-icons no-padding">face</i> </li> <li> <p class="left" style="font-weight: 500; color: #353535">' + respon.email + '</p> <p class="left" style="font-weight: 500; color: #335d82; font-size: 12px; margin-left: 5px"> đã đăng một thảo luận</p> </li> <li></li> </li> </ul> </div> <div class="row cm-item-content"> <p class="no-margin" style="font-size: 18px; font-weight: 500; color: #59657D">' +respon.title+ '</p> <p style="margin: 0px 0px 0px 0px">' + respon.description + '</p> </div> </div>'
		      $('.lecture-comment-list').prepend(comment_item);
		        $('#comment-dropdown').fadeOut(225);
     			  $('#comment-dropdown').removeClass('active');
		    }
			});

		})
	// search comment when typing
	$('#search-comment').on('input', function (){
		var key_words = $(this).val();
		if(key_words.trim() != ''){
			var list_comment = $('.cm-item');
			list_comment.each(function (){
				var item_comment = $(this);
				var isFind = false;
				item_comment.find(".cm-item-content").each(function (){
					if( $(this).text().toLowerCase().indexOf(key_words.toLowerCase()) > 0 ){
						isFind = true;
					}
				})
				if(!isFind){
					item_comment.attr("style", "display: none");
				}
				else{
					item_comment.attr("style", "display: block");
				}
			});
		}
		else{
			var list_comment = $('.cm-item');
			list_comment.each(function (){
				$(this).attr("style", "display: block");
			});
		}
		
	})
})