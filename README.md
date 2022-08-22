# coconut-mobile
PouchDB backed client for Coconut. Offline capable. Couchapp deployable. Connects to a coconut-cloud.

Coconut is a platform that is used to develop applications for collecting data. There are many other better and simpler applications if you are simply collecting data, but Coconut as a platform is designed to help build tools that align closely with activities or workflows that are carried out in the field. The aim is to build tools that don't get in the way of the job that is getting done, rather they should guide someone through their work, and hopefully even make the job easier and deliver better data quality.

Coconut Mobile is the progressive web app (not using the latest and greatest PWA stuff unfortunately). It lets you collect data for question sets (forms, but we don't like to use that word because we want to break the paper mindset!) that are designed in the cloud portion of the application. Coconut Mobile uses crypto pouch for client side encryption. The structure of the code follows the structure of a "couchapp", a self-contained package that allow us to deploy the app (a website basically) from couchdb itself (couchdb is a http server, so in addition to acting as a database it can also serve the site itself). A few other things to mention about the architecture: 

* we are using backbone.js as the structure for the application, this is basically a small MVC library
* everything is written in coffeescript, which compiles to javascript
* we use browserify to manage all of the javascript libraries and bundle them into a single file for deployment (using the command npm run start).

To modify Coconut in order to handle project specific activities, there is a plugin architecture. So when the project needs a custom user interface, or additional features like being able to transfer the responsibility for a piece of data to someone else on the time, that gets built as a plugin. Some example plugins include:

https://github.com/ICTatRTI/coconut-mobile-plugin-zanzibar (malaria surveillance)
https://github.com/ICTatRTI/coconut-mobile-plugin-outbreak (ebola contact tracing)

More specific documentation:

A Question Set is a list of questions. Each question set can be rendered and then the data collected saved. When defining a question there are various options to configure it's behavior:

  * required
  * validation
  * action_on_questions_loaded - can be attached to a single question or to the question set itself.
  * action_on_change
  * skip_logic
  * onValidatedComplete
  
### Installation

```
npm run install-server
```


