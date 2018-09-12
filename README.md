## Speech-Recognition
This is a simple demo app for Speech recognition using Objective-C. I created this because most of the available documentation and stack overflow posts are for Swift.

### Instructions & Notes

* Download the Project.

* Remember to modify the .plist file to get user's authorization for Speech Recognition and using the microphone, of course the `<String>` value must be customized to your needs, you can do this by creating and modifying the values in the `Property List` or right-click on the `.plist` file and `Open As` -> `Source Code` and paste the following lines before the `</dict>` tag.
```
<key>NSMicrophoneUsageDescription</key>  <string>This app uses your microphone to record what you say, so watch what you say!</string>

<key>NSSpeechRecognitionUsageDescription</key>  <string>This app uses Speech recognition to transform your spoken words into text and then analyze the, so watch what you say!.</string>
```
* In order to be able to import the Speech framework into the project you need to have iOS 10.0+.

* **Run the app!**

* It has a very basic UI, just press the `Go!` button and start talking, whatever you say must be being logged in the console (`NSLog` is the only thing receiving the text). Pressing the `Go!` button again will stop the recording.

* More detailed instructions in the code comments.
