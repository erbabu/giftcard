# giftcard
Gift Card Android application developed for Brother Hackathon 2020.
## Goal
Social good application to support local businesses for introducing gift cards of their own store with their existing resources.
### Pre-requisites
- Android smartphone with a version higher than Lollipop
- Brother label printer QL-820NWB
  - If there is no availability of the said label printer, then use some website (like https://www.online-qrcode-generator.com/) for generating QR code of the gift card number and print it for customer using any regular printer with a gift card template (created using any document software). You may use the attached gift card template word document as well.
- Flutter development environment with an emulator / phone to test (Android preferrably) [Ref link](https://codelabs.developers.google.com/codelabs/flutter-firebase/#2)
### Steps to use:
- Open the app and click refresh icon to get a new gift card number (19 digit number). It will automatically populate the number in another place in the screen where transaction data is shown.
- Select the gift card amount. It will automatically populate the amount in another place in the screen where transaction data is shown.
- Include associated reference text for this card in the respective field (usually phone number but it is a string field).
- Create card button creates the gift card in firestore database through API. It is not linked to any payment system, instead it is a record keeping transaction system. For a deviceID, in this demo app, only 5 cards are allowed.
- Similarly buttons are provided to deduct balance, check balance, load additional gift card balance, disable and enable gift card.
### Block diagram
![Gift Card block diagram](GiftcardAppBH2020-Diagram.png)
### Technology
- Flutter + Dart
- Firebase; Firestore Native Database
- Brother P-Touch editor for label printer templates
- Flutter plug-ins like Brother Label Printer, QR code creator and scanner
### Shared files
- GiftCard-good.lbx (Label printer P-Touch template)
- giftcard-v1-main.dart (Flutter Dart file)
- Don't forget to include additional files in flutter project
  - Store logo and refresh icon images
  - google-services file for connecting to firebase
### Implemented
- Generate a random 19 digit card number (something similar to 16 digit credit card number + 3 digit cvv), allows to select gift card amount, prints gift card in QL-820NWB connected in the same Wi-Fi as phone using p-touch template (default store logo and name)
- Gift card has the card number as QR code as well along with the card number so that we can use the QR reader in-built into the app to read the card number and do the transactions
- **Actions** implemented based on newly generated / read card number through QR reader - Creates the gift card in firestore native database , enable / disable card, check balance, load additional amount to the card, and deducting transaction amount. Option is there to have one additional reference field which could be used for associating phone number with the card number.

Hope this app will allow a small business to kick start using their own gift card without much hazzle. 
### In the pipeline
- Generalization of store logo, name and printer IP address
- Listing of transactions for the card number
- Searching the card by phone number and use it for transactions
- Use the card as a dual card (rewards card + gift card) so that with phone number, rewards in all cards could be collectively used
- Publishing the app in major App stores (like Amazon app store, Google play store, Apple app store)
### References
- Firebase Database [Youtube Video](https://www.youtube.com/watch?v=DqJ_KjFzL9I)
- Printing label using P-Touch template [Youtube Video](https://www.youtube.com/watch?v=1EgXb-bHmc0)
- Flutter app development [Youtube Video](https://www.youtube.com/watch?v=I9ceqw5Ny-4&list=PLSzsOkUDsvdtl3Pw48-R8lcK2oYkk40cm); [Free course](https://www.appbrewery.co/p/intro-to-flutter)
- Flutter plug-ins
  - Brother Printer (https://pub.dev/packages/brotherlabelprintdart)
  - QR creator (https://pub.dev/packages/qr_flutter)
  - QR scanner (https://pub.dev/packages/flutter_barcode_scanner)
  - Firebase and Firestore
