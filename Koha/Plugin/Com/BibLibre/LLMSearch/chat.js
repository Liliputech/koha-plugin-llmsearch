$(document).ready(function() {
    $('div#report-koha-url').parent().after('<div class="col-sm-auto"><button class="btn btn-primary open-button" onclick="openForm()" title="AI Chat" aria-label="AI Chat"><i class="fa-solid fa-robot"></i></button></div>');
    
    fetch('/api/v1/contrib/llmsearch/static/chat.html')
        .then(response => response.text())
        .then(html => {
            $('body').append(html);
	    populateChat();
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

    addMessage('assistant', '<div class="loading-dots"><span>.</span><span>.</span><span>.</span></div>', 0);

    chatWindow.scrollTop(chatWindow[0].scrollHeight);
    $.post('/api/v1/contrib/llmsearch/chat', { json : sessionStorage.getItem('current_chat') }, function(data) {
        console.log(data);
        if (data.choices && data.choices.length > 0) {
            const content = data.choices[0].message.content;
	    const clean = DOMPurify.sanitize(content);
            $('div.chat-messages div.assistant:last p').html(clean);
	    saveMessage('assistant', clean);
            chatWindow.scrollTop(chatWindow[0].scrollHeight);
        }
    }).fail(function() {
	alert( "AJAX error, check the plugin configuration or javascript console" );
    });
}

function addMessage(role, content, save=1) {
    icon = role == 'assistant' ? 'robot' : 'user' ;
    var messageDiv = $('<div>', { 'class': 'message ' + role });

    var icon = $('<i>', { 'class': 'fa-solid fa-' + icon });

    var paragraph = $('<p>').html( content );
    messageDiv.append(icon);
    messageDiv.append(paragraph);
    $('div.chat-messages').append(messageDiv);
    if (save) saveMessage(role, content);
}

function saveMessage(role, content) {
    var current_chat = sessionStorage.getItem("current_chat");
    if (current_chat === null) {
	current_chat = [];
    }
    else {
	current_chat = JSON.parse(current_chat);
    }
    const message = {role:role, content:content};
    current_chat.push(message);
    sessionStorage.setItem("current_chat", JSON.stringify(current_chat));
}

function populateChat() {
    $.get('/api/v1/contrib/llmsearch/welcome', function(data) {
        addMessage('assistant', data)
    });

    var current_chat = sessionStorage.getItem("current_chat");
    if (current_chat === null) {
	current_chat = [];
    }
    else {
	current_chat = JSON.parse(current_chat);
    }

    current_chat.forEach(item => {
	addMessage(item.role, item.content, 0);
    });
}

function resetChat() {
    sessionStorage.removeItem("current_chat");
    $('div.chat-messages').children().slice(1).remove();
}
