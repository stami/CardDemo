//
//  ViewController.swift
//  CardDemo
//
//  Created by Samuli Tamminen on 3.7.2017.
//  Copyright © 2017 Samuli Tamminen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  // MARK: - Views
  var visualEffectView: UIVisualEffectView!
  var cardViewController: CardViewController!

  // MARK: - Constants
  let cardHeight: CGFloat = 400
  let cardTitleHeight: CGFloat = 60.0

  // MARK: - Animation variables
  enum CardState {
    case expanded
    case collapsed
  }

  var cardIsVisible: Bool = false
  var nextState: CardState {
    return cardIsVisible ? .collapsed : .expanded
  }

  var runningAnimations = [UIViewPropertyAnimator]()
  var animationProgressWhenInterrupted: CGFloat = 0.0

  // MARK: - Setup

  override func viewDidLoad() {
    super.viewDidLoad()
    setupCard()
  }

  func setupCard() {

    // Add blur background
    visualEffectView = UIVisualEffectView()
    visualEffectView.frame = view.frame
    view.addSubview(visualEffectView)

    // Setup CardViewController
    cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)

    addChildViewController(cardViewController)
    view.addSubview(cardViewController.view)

    let cardFrame = CGRect(x: 0,
                           y: view.frame.height - cardTitleHeight,
                           width: view.bounds.width,
                           height: cardHeight)

    cardViewController.view.frame = cardFrame

    setupGestures()
  }

  // MARK: - Tap and pan gestures

  func setupGestures() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                      action: #selector(ViewController.handleCardTap))

    cardViewController.titleBar.addGestureRecognizer(tapGestureRecognizer)

    let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                      action: #selector(ViewController.handleCardPan))

    cardViewController.titleBar.addGestureRecognizer(panGestureRecognizer)
  }

  @objc
  func handleCardTap(recognizer: UITapGestureRecognizer) {
    switch recognizer.state {
    case .ended:
      animateTransitionIfNeeded(state: nextState, duration: 0.3)
      break
    default: break
    }
  }

  @objc
  func handleCardPan(recognizer: UIPanGestureRecognizer) {
    switch recognizer.state {

    case .began:
      startInteractiveTransition(state: nextState, duration: 0.3)

    case .changed:
      let translation = recognizer.translation(in: self.cardViewController.titleBar)
      var fractionComplete = translation.y / (cardHeight - cardTitleHeight)
      fractionComplete = cardIsVisible ? fractionComplete : -fractionComplete
      updateInteractiveTransition(fractionComplete: fractionComplete)

    case .ended:
      continueInteractiveTransition()
    default:
      break
    }
  }

  // MARK: - Animations

  // Perform all animations with animators if not already running
  func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
    if runningAnimations.isEmpty {

      // MARK: Frame
      let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
        switch state {
        case .expanded:
          self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
        case .collapsed:
          self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardTitleHeight
        }
      }

      // Clear animations when completed
      frameAnimator.addCompletion { _ in
        self.cardIsVisible = !self.cardIsVisible
        self.runningAnimations.removeAll()
      }

      frameAnimator.startAnimation()
      runningAnimations.append(frameAnimator)

      // MARK: Arrow
      let arrowAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
        switch state {
        case .expanded:
          self.cardViewController.arrow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        case .collapsed:
          self.cardViewController.arrow.transform = CGAffineTransform(rotationAngle: 0)
        }
      }

      arrowAnimator.startAnimation()
      runningAnimations.append(arrowAnimator)

      // MARK: Blur
      let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
        switch state {
        case .expanded:
          self.visualEffectView.effect = UIBlurEffect(style: .dark)
        case .collapsed:
          self.visualEffectView.effect = nil
        }
      }

      blurAnimator.startAnimation()
      runningAnimations.append(blurAnimator)
    }
  }

  // Called on pan .began
  func startInteractiveTransition(state: CardState, duration: TimeInterval) {
    if runningAnimations.isEmpty {
      animateTransitionIfNeeded(state: state, duration: duration)
    }
    for animator in runningAnimations {
      animator.pauseAnimation()
      animationProgressWhenInterrupted = animator.fractionComplete
    }
  }

  // Called on pan .changed
  func updateInteractiveTransition(fractionComplete: CGFloat) {
    for animator in runningAnimations {
      animator.fractionComplete = fractionComplete + animationProgressWhenInterrupted
    }
  }

  // Called on pan .ended
  func continueInteractiveTransition() {
    for animator in runningAnimations {
      animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
  }
}
