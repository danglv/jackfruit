$(document).ready(function () {
	$("#change-password-form").validate({
		rules: {
			"user[current_password]": {required: true},
			"user[password]": {required: true, minlength: 6},
			"user[password_confirmation]": {required: true, equalTo: "#user_password"}
		},
		messages: {
	    "user[current_password]": "Vui lòng nhập mật khẩu hiện tại",
	    "user[password_confirmation]":{
	    	required:  "Vui lòng xác nhận lại mật khẩu",
	    	equalTo: "Xác nhận mật khẩu không đúng"
	    },
	    "user[password]": {
	      minlength: "Mật khẩu cần ít nhất 6 kí tự",
	      required: "Vui lòng nhập mật khẩu mới"
	    }
		}
	});
});