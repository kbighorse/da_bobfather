<% if @error %>
  $("#get_friends").html("You Have a lot of friends.  Please reload the page to continue importing your friend list");
<% else %>
  $("#get_friends").html("<%= escape_javascript(render :partial => 'users/form') %>");
<% end %>