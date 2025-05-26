# Koha LLM Search

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
Happy playing!
