$(document).ready(function() {
    $('div#report-koha-url').parent().after('<div class="col-sm-auto"><button class="btn btn-primary open-button" onclick="openForm()" title="AI Chat" aria-label="AI Chat"><i class="fa-solid fa-robot"></i></button></div>');
    
    fetch('/api/v1/contrib/llmsearch/static/chat.html')
        .then(response => response.text())
        .then(html => {
            $('body').append(html);
            $('form.chat-container').on('submit', function(event) {
                event.preventDefault();
                askAI();
            });
        })
        .catch(error => {
            console.error('Error fetching the HTML file:', error);
        });
});

function openForm() {
  document.getElementById("llm-chat").style.display = "block";
}

function closeForm() {
  document.getElementById("llm-chat").style.display = "none";
}

function askAI() {
    var chatInput = $('div#llm-chat input');
    var inputValue = chatInput.val();
    var chatWindow = $('div.chat-messages');
    addMessage('user', inputValue);
    chatInput.val('');

    addMessage('robot', '<div class="loading-dots"><span>.</span><span>.</span><span>.</span></div>');

    chatWindow.scrollTop(chatWindow[0].scrollHeight);
    ///*
    $.post('/api/v1/contrib/llmsearch/chat', { input: inputValue }, function(data) {
        console.log(data);
        if (data.choices && data.choices.length > 0) {
            var content = data.choices[0].message.content;
            $('div.chat-messages div.robot:last p').html(content);
            chatWindow.scrollTop(chatWindow[0].scrollHeight);
        }
    });
    //*/
}

function addMessage(type, content) {
    var messageDiv = $('<div>', { 'class': 'message ' + type });

    var icon = $('<i>', { 'class': 'fa-solid fa-' + type });

    var paragraph = $('<p>').html( content );
    messageDiv.append(icon);
    messageDiv.append(paragraph);
    $('div.chat-messages').append(messageDiv);
}
