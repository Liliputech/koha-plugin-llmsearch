$(document).ready(function() {
    $("select#masthead_search").append('<option value="llmsearch">Search with AI</option>');
    
    $('#searchform').submit(function(event) {
        event.preventDefault();

        var selectedOption = $('#masthead_search').val();
        if (selectedOption === 'llmsearch') {
            var inputValue = $('form#searchform input[type=text]').val();
            $.post('/api/v1/contrib/llmsearch/chat', { input: inputValue }, function(data) {
                console.log(data);
                if (data.choices && data.choices.length > 0) {
                    var message = data.choices[0].message.content;
                    alert(message);
                }
            });
        }
    });
});
