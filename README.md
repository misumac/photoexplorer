# photoexplorer

An app designed to explore 500px and Flickr photos.
Functions:
* 500 px: browse by categories, popular, editor picks, etc
* search terms for both providers
* Check the exif info if available
* User gallery
* Bookmark any user and you will get notifications when there are posts you haven't seen.

## Running the project
You must acquire application keys from the providers and place them where they are needed, just build and you will get the errors.
For the moment, the pods are not added as sources, so a 'pod install' is needed to get them.

## Technical discussion
This project is made to demonstrate several development tools, patterns and techniques:
- MVVM architecture
- RxSwift as a solution both for binding the view to the viewmodel but also to leverage the async tasks
- Realm as a persistence store, although the requirements for this projects are extremely light
- Protocols for abstracting the image providers were used
- Dependency injection came nicely into play and it was facilitated by the great Swinject framework https://github.com/Swinject/Swinject together with sotryboard support
- A nice (hopefully) mozaic algorithm that allows me to present thumbnails in a gallery without any cropping and without any gaps between them
- The gallery scrolls infinitely and performs greatly even on an iPhonne 4s thanks to the HanekeSwift cache https://github.com/Haneke/HanekeSwift which makes handling thumbnail images a breeze. 
- With the help of Rx, the large image view loads the image in a two step process: a medium sized one is presented and a full resolution version is loaded when zooming in.

## More to come:
- Complete error handling
- Some Rx constructs are not as elegant as they could be
- Tests :)
- Suggestions?

