$(document).ready(function (){
	$('#comment-dropdown').click(function (e){
	  	e.stopPropagation(); 
		});
	// send request to add comment 
	$('#send-comment').click(function (){
			var course_id = $("#course-id").val();
	  	var _title = $("#comment-title").val();
	  	var _description = $("#comment-content").val();
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
		      var comment_item = '<div class="col s12 no-padding cm-item"> <div class="row cm-item-header no-margin"> <ul class="no-margin"> <li> <i class="small material-icons no-padding">face</i> </li> <li> <p>' + respon.email + ' đã đăng một thảo luận</p> </li> <li></li> <!-- / %p - --> <li> <!-- /%p 1 tháng trước --> </li> </ul> </div> <div class="row cm-item-content"> <p class="no-margin" style="font-weight: 500">' + respon.title + '</p> <p>' + respon.description +'</p> </div> </div>'
		      $('.lecture-comment-list').prepend(comment_item);
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
					if( $(this).text().indexOf(key_words) > 0 ){
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