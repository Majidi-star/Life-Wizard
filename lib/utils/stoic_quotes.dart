import 'dart:math';

class StoicQuotes {
  static final List<String> quotes = [
    "The obstacle is the way. - Marcus Aurelius",
    "You have power over your mind - not outside events. Realize this, and you will find strength. - Marcus Aurelius",
    "Waste no more time arguing what a good man should be. Be one. - Marcus Aurelius",
    "First say to yourself what you would be; then do what you have to do. - Epictetus",
    "It's not what happens to you, but how you react to it that matters. - Epictetus",
    "We suffer more in imagination than in reality. - Seneca",
    "Luck is what happens when preparation meets opportunity. - Seneca",
    "The best revenge is to be unlike him who performed the injury. - Marcus Aurelius",
    "If it is not right, do not do it, if it is not true, do not say it. - Marcus Aurelius",
    "He who fears death will never do anything worthy of a living man. - Seneca",
    "No person has the power to have everything they want, but it is in their power not to want what they don't have. - Seneca",
    "The happiness of your life depends upon the quality of your thoughts. - Marcus Aurelius",
    "You become what you give your attention to. - Epictetus",
    "If you want to improve, be content to be thought foolish and stupid. - Epictetus",
    "The key is to keep company only with people who uplift you, whose presence calls forth your best. - Epictetus",
    "He who is brave is free. - Seneca",
    "Difficulties strengthen the mind, as labor does the body. - Seneca",
    "The mind adapts and converts to its own purposes the obstacle to our acting. - Marcus Aurelius",
    "You have power over your mind - not outside events. Realize this, and you will find strength. - Marcus Aurelius",
    "The best revenge is to be unlike him who performed the injury. - Marcus Aurelius",
    "Waste no more time arguing what a good man should be. Be one. - Marcus Aurelius",
    "First say to yourself what you would be; then do what you have to do. - Epictetus",
    "It's not what happens to you, but how you react to it that matters. - Epictetus",
    "We suffer more in imagination than in reality. - Seneca",
    "Luck is what happens when preparation meets opportunity. - Seneca",
    "The best revenge is to be unlike him who performed the injury. - Marcus Aurelius",
    "If it is not right, do not do it, if it is not true, do not say it. - Marcus Aurelius",
    "He who fears death will never do anything worthy of a living man. - Seneca",
    "No person has the power to have everything they want, but it is in their power not to want what they don't have. - Seneca",
    "The happiness of your life depends upon the quality of your thoughts. - Marcus Aurelius",
  ];

  static String getRandomQuote() {
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }
}
