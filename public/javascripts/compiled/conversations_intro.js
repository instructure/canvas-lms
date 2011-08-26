(function() {
  I18n.scoped('conversations_intro', function(I18n) {
    return $.conversationsIntroSlideshow = function() {
      var introSlideshow;
      introSlideshow = new window.Slideshow('conversations_intro');
      introSlideshow.addSlide(I18n.t('titles.slide1', 'Slide 1'), function(slide) {
        slide.addImage('/images/conversations/intro/icon.png', 'icon');
        slide.addParagraph(I18n.t('slide1.paragraph1', 'Take a look at your Inbox!'), 'large');
        slide.addParagraph(I18n.t('slide1.paragraph2', 'Conversations—the new Canvas messaging system—has arrived!'), 'large');
        slide.addParagraph(I18n.t('slide1.paragraph3', 'Use Conversations to send a private message to a classmate or use Conversations to talk to an entire group of people.'), 'large_and_blue');
        return slide.addParagraph(I18n.t('slide1.paragraph4', 'Ready for a short intro? Click the right arrow to get started.'), 'large');
      });
      introSlideshow.addSlide(I18n.t('titles.slide2', 'Slide 2'), function(slide) {
        slide.addImage('/images/conversations/intro/image2.png', 'screenshot');
        slide.addParagraph(I18n.t('slide2.paragraph1', 'All your conversations are shown on the left side.'));
        return slide.addParagraph(I18n.t('slide2.paragraph2', 'You can see who the conversation is with, how many messages there are, and a few lines from the newest message in each conversation.'));
      });
      introSlideshow.addSlide(I18n.t('titles.slide3', 'Slide 3'), function(slide) {
        slide.addImage('/images/conversations/intro/image3.png', 'screenshot');
        slide.addParagraph(I18n.t('slide3.paragraph1', 'Conversations can be marked as read/unread, archived, or labeled by color using the "actions" button on the message.'));
        return slide.addParagraph(I18n.t('slide3.paragraph2', 'Archived messages aren\'t deleted, they\'re just moved out of your inbox, so you can access them again if needed.'));
      });
      introSlideshow.addSlide(I18n.t('titles.slide4', 'Slide 4'), function(slide) {
        slide.addImage('/images/conversations/intro/image4.png', 'screenshot');
        return slide.addParagraph(I18n.t('slide4.paragraph1', 'When you select a conversation, all the messages for that conversation are shown in the panel on the right. When conversations get long, you can always scroll down to see earlier messages.'));
      });
      introSlideshow.addSlide(I18n.t('titles.slide5', 'Slide 5'), function(slide) {
        slide.addImage('/images/conversations/intro/image5.png', 'screenshot');
        return slide.addParagraph(I18n.t('slide5.paragraph1', 'To begin a message, start by clicking the Compose icon.'));
      });
      introSlideshow.addSlide(I18n.t('titles.slide6', 'Slide 6'), function(slide) {
        slide.addImage('/images/conversations/intro/image6.png', 'screenshot');
        slide.addParagraph(I18n.t('slide6.paragraph1', 'In the New Message box, start typing the person, or group\'s name, and they\'ll show up in the dropdown. Alternatively, you can click the address book icon to find someone if you don\'t remember a name.'));
        return slide.addParagraph(I18n.t('slide6.paragraph2', 'Type your message, click Send, and you\'re golden.'));
      });
      introSlideshow.addSlide(I18n.t('titles.slide7', 'Slide 7'), function(slide) {
        slide.addImage('/images/conversations/intro/image7.png', 'screenshot');
        slide.addParagraph(I18n.t('slide7.paragraph1', 'You can send messages to one person or to a group of people. By default all group messages are available to everyone in the group.'));
        return slide.addParagraph(I18n.t('slide7.paragraph2', 'If you wanted to send the message privately to all the recipients, uncheck the "This is a group conversation" checkbox.'));
      });
      introSlideshow.addSlide(I18n.t('titles.slide8', 'Slide 8'), function(slide) {
        slide.addImage('/images/conversations/intro/image8.png', 'screenshot');
        slide.addParagraph(I18n.t('slide8.paragraph1', 'You can select one or more messages by clicking the checkbox on the right hand side.'));
        return slide.addParagraph(I18n.t('slide8.paragraph2', 'Once selected, you can forward them to someone else, or delete them.'));
      });
      introSlideshow.addSlide(I18n.t('titles.slide9', 'Slide 9'), function(slide) {
        slide.addImage('/images/conversations/intro/image9.png', 'screenshot', 'http://www.youtube.com/watch?v=NWqIaEyVWZM');
        slide.addParagraph(I18n.t('slide9.paragraph1', 'We think you\'ll find Conversations simple and easy to use.'));
        slide.addParagraph(I18n.t('slide9.paragraph2', 'Check out this short introduction video to see Conversations in action.'));
        return slide.addParagraph(I18n.t('slide9.paragraph3', 'Your old messages have been organized into Conversations for you. So what are you waiting for? Get started!'));
      });
      introSlideshow.dom.bind('dialogclose', function() {
        return $.ajaxJSON('/conversations/watched_intro', 'POST', {});
      });
      return introSlideshow.start();
    };
  });
}).call(this);
