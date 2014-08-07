//
//  CNREPLViewController.m
//  REPL
//
//  Created by Charles Cheever on 8/5/14.
//  Copyright (c) 2014 CoreNode. All rights reserved.
//

#import "CNREPLViewController.h"

#import <JavaScriptCore/JavaScriptCore.h>
#import <CoreNode/CoreNode.h>

@interface CNREPLViewController ()

@end

@implementation CNREPLViewController {
    UIButton *_clearButton;
    UIButton *_evalButton;

    UIView *_keyboardPlaceholderView;
    NSLayoutConstraint *_keyboardConstraint;

    CNRuntime *_runtime;

}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup the UI

    _inputTextView = [UITextView new];

    //_inputTextView.backgroundColor = [UIColor orangeColor];
    _inputTextView.text = @"And if you see my reflection in the snow covered hills, then maybe, the landslide will bring you down. Happy birthday Sieg!";

    _inputTextView.editable = YES;
    _inputTextView.text = @"\"JavaScript here\" + String.fromCharCode(32) + \"will be evaluated\";";
    _inputTextView.font = [UIFont fontWithName:@"LiberationMono" size:13.0];
    _inputTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _inputTextView.layer.borderWidth = 1.0;
    _inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_inputTextView];

    _outputTextView = [UITextView new];

    //_outputTextView.backgroundColor = [UIColor greenColor];
    _outputTextView.text = @"Results of evaluation will appear here";

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
    JSContext *context = [[JSContext alloc] initWithVirtualMachine:[[JSVirtualMachine alloc] init]];
#if defined(__IPHONE_8_0)
    if ([context respondsToSelector:@selector(setName:)]) {
        context.name = @"Core Node";
    }
#endif

    NSURL *rootUrl = [[NSBundle mainBundle] resourceURL];

    NSURL *mainScriptUrl = [CNRuntime urlWithBase:rootUrl filePath:@""];
    _runtime = [[CNRuntime alloc] initWithContext:context rootUrl:rootUrl];

#if defined(DEBUG)
    setenv("NODE_ENV", "development", 1);
#else
    setenv("NODE_ENV", "production", 1);
#endif

    NSLog(@"mainScriptUrl=%@", mainScriptUrl);
    [_runtime installNodeWithMainScript:mainScriptUrl];

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

    JSContext *context = _runtime.context;
    NSString *script = _inputTextView.text;
    JSValue *util = [CNRuntime evaluateCallbackScript:@"require('util')" inContext:context];
    JSValue *result = [CNRuntime evaluateCallbackScript:script inContext:context];

    // TODO: Handle problems with `inspect` not being able to handle the resulting value
    NSString *inspectedResult = [[util invokeMethod:@"inspect" withArguments:@[result]] toString];

    if (context.exception) {
        NSString *exceptionText = [context.exception errorString];
        _outputTextView.textColor = [UIColor redColor];
        _outputTextView.text = exceptionText;
        _runtime.context.exception = nil;


    } else {
        _outputTextView.textColor = [UIColor darkTextColor];
        _outputTextView.text = inspectedResult;
        _runtime.context[@"_"] = result;
    }


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
