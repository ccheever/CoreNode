//
//  CNREPLViewController.m
//  REPL
//
//  Created by Charles Cheever on 8/5/14.
//  Copyright (c) 2014 CoreNode. All rights reserved.
//

#import "CNREPLViewController.h"

@interface CNREPLViewController ()

@end

@implementation CNREPLViewController {
    UIButton *_clearButton;
    UIButton *_evalButton;

    UIView *_keyboardPlaceholderView;
    NSLayoutConstraint *_keyboardConstraint;

}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup the UI

    _inputTextView = [UITextView new];

    //_inputTextView.backgroundColor = [UIColor orangeColor];
    _inputTextView.text = @"And if you see my reflection in the snow covered hills, then maybe, the landslide will bring you down. Happy birthday Sieg!";

    _inputTextView.editable = YES;
    _inputTextView.text = nil; // @"This is the input text view";
    _inputTextView.font = [UIFont fontWithName:@"LiberationMono" size:13.0];
    _inputTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _inputTextView.layer.borderWidth = 1.0;
    _inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_inputTextView];

    _outputTextView = [UITextView new];

    //_outputTextView.backgroundColor = [UIColor greenColor];
    _outputTextView.text = @"When times get bad, when times get rough, won't you lay me down in tall grass and let me do my sutff. Love you mommy.";

    _outputTextView.editable = NO;
    _outputTextView.font = [UIFont fontWithName:@"LiberationMono" size:13.0];
    _outputTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _outputTextView.layer.borderWidth = 1.0;
    _outputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_outputTextView];

    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_clearButton addTarget:self action:@selector(_clearButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    //_clearButton.frame = CGRectMake(10.0, 332.0, 145.0, 20.0);
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_clearButton];

    _evalButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_evalButton addTarget:self action:@selector(_evalButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_evalButton setTitle:@"Eval" forState:UIControlStateNormal];
    //_evalButton.frame = CGRectMake(160.0, 332.0, 145.0, 20.0);
    _evalButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_evalButton];

    _keyboardPlaceholderView = [UIView new];
    _keyboardPlaceholderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_keyboardPlaceholderView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];

    [_inputTextView becomeFirstResponder];

    [self installConstraints];

    // Set up CoreNode

}


/*
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.view setNeedsLayout];
    [self.view setNeedsUpdateConstraints];

    [UIView animateWithDuration:0.5 delay:0.0 options:0 animations:^{
        [self.view updateConstraintsIfNeeded];
        [self.view layoutIfNeeded];
    } completion:nil];

}
 */

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"didRotateFromInterfaceOrientation");
    [self.view setNeedsUpdateConstraints];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    NSLog(@"willRotateToInterfaceOrientation");
    [self.view setNeedsUpdateConstraints];
}


- (void)installConstraints {

    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_inputTextView, _outputTextView, _clearButton, _evalButton, _keyboardPlaceholderView);

    NSArray *constraintsVertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-22-[_outputTextView]-[_inputTextView(==_outputTextView)]-[_evalButton]-[_keyboardPlaceholderView]|" options:0 metrics:nil views:viewsDictionary];

    _keyboardConstraint = constraintsVertical[[constraintsVertical count] - 1];
    NSArray *constraintsHorizontalOutput = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_outputTextView]-|" options:0 metrics:nil views:viewsDictionary];
    NSArray *constraintsHorizontalInput = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_inputTextView]-|" options:0 metrics:nil views:viewsDictionary];
    NSArray *constraintsHorizontalButtons = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_clearButton]-[_evalButton(==_clearButton)]-|" options:NSLayoutFormatAlignAllTop metrics:nil views:viewsDictionary];

    [self.view addConstraints:constraintsVertical];
    [self.view addConstraints:constraintsHorizontalOutput];
    [self.view addConstraints:constraintsHorizontalInput];
    [self.view addConstraints:constraintsHorizontalButtons];

}

- (void)viewDidLayoutSubviews {
    [_outputTextView layoutIfNeeded];
}

- (void) keyboardDidShow:(NSNotification*)notification {

    NSLog(@"keyboardDidShow");

    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;


    _keyboardConstraint.constant = keyboardFrame.size.height;
    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];


    [UIView animateWithDuration:animationDuration delay:0.0 options:curve animations:^{
        [self.view layoutIfNeeded];
        [self.view updateConstraintsIfNeeded];
    } completion:nil];


}

- (void) keyboardDidHide:(NSNotification*)notification {

    NSLog(@"keyboardDidHide");

    NSDictionary *userInfo = [notification userInfo];
    //CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;


    _keyboardConstraint.constant = 0.0;
    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];

    [UIView animateWithDuration:animationDuration delay:0.0 options:curve animations:^{
        [self.view layoutIfNeeded];
        [self.view updateConstraintsIfNeeded];
    } completion:nil];

}

- (void)_clearButtonTapped:(UIButton *)sender {
    NSLog(@"_clearButtonTapped");
}

- (void)_evalButtonTapped:(UIButton *)sender {
    NSLog(@"_evalButtonTapped");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
