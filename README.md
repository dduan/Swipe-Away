This a iOS 7 demo of user interaction with UIView achieved via UIDynamics.

The view rotates and moves as user pans over it. When the gesture ends, if the
velocity is smaller than a threshold, the view snaps back to its original
positon, otherwise it gains an acceleration in the direciton of its veleocity
and moves out of the screen.

Design is inspired by [TweetBot](http://tapbots.com/software/tweetbot/).

Implementation heavily relied on this answer on
[StackOverflow](http://stackoverflow.com/a/21346822/243798).


This code is releaed to the public domain.
