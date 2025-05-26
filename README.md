# Koha LLM Search

![animation of the plugin at work](llmsearch.gif?raw=true)

## Introduction
This plugin is a first attempt at creating a LLM search plugin.
The architecture idea is to have the LLM only do a "translation" between a users request in natural language to a Koha Search forwarding. 

For now, it adds a "Robot" button at the bottom right of the OPAC.
A click on that button opens a chat overlay.
Given every aspect of the configuration has been done, you can already use any LLM on Koha's OPAC!
The configuration need an API Key from any provider compatible with OpenAI API.
You could use Mistral or Ollama for example. I've used Mistral during my tests.
If you want to use another platform, you will need to provide the base url of your LLM service provider, and the model you'll want to use.
Those are kind "Expert-mode" configuration.

## Disclaimer
Running this plugin in production can generate a lot of API calls to an LLM hosting external service.
Especially when available on your OPAC without authentication and visible to all users and bots from the internet.
This - CAN - lead to unexpected costs!

Make sure you know what you're doing, try in a test environment.
It is recommended to roughly evaluate the average number of visitors your OPAC receives each day (for example using Matomo) to evaluate the cost.

Also be aware that this plugin WILL forward your users query to an external service.
Depending on the provider, this one can be either or all of the following :
 - non-libre
 - expensive
 - ecologicaly unfriendly
 - biaised
 - use your patrons requests to train their model or sell the data.

Given patrons do not disclose personnal information in the chat, none will be sent to the external service by this plugin.
Be safe, have fun!
