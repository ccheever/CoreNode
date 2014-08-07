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

    // The input field where you type stuff into
    _inputTextView = [UITextView new];
    _inputTextView.editable = YES;
    _inputTextView.text = @"\"JavaScript here\" + String.fromCharCode(32) + \"will be evaluated\";";
    _inputTextView.font = [UIFont fontWithName:@"LiberationMono" size:13.0];
    _inputTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _inputTextView.layer.borderWidth = 1.0;
    _inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_inputTextView];

    // The ouptut field where your results go
    _outputTextView = [UITextView new];
    _outputTextView.text = @"Results of evaluation will appear here";
    _outputTextView.editable = NO;
    _outputTextView.font = [UIFont fontWithName:@"LiberationMono" size:13.0];
    _outputTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _outputTextView.layer.borderWidth = 1.0;
    _outputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_outputTextView];

    // Button that clears the input field
    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_clearButton addTarget:self action:@selector(_clearButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_clearButton];

    // Button that lets you evaluate code
    _evalButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_evalButton addTarget:self action:@selector(_evalButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_evalButton setTitle:@"Eval" forState:UIControlStateNormal];
    _evalButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_evalButton];

    // A view we use as a placeholder to handle the keyboard while using autolayout
    _keyboardPlaceholderView = [UIView new];
    _keyboardPlaceholderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_keyboardPlaceholderView];

    // We want to know about the keyboard being shown/hidden so we can adjust the UI accordingly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];

    // Focus on the input text box when the view first appears
    [_inputTextView becomeFirstResponder];

    // This will setup the view to work with autolayout
    [self installConstraints];

    // Set up CoreNode

    // Make a new JS Context
    // We can also use a JS context from a UIWebView (but unfor
    JSContext *context = [[JSContext alloc] initWithVirtualMachine:[[JSVirtualMachine alloc] init]];

    // In iOS8 and above, you can give a context a name
#if defined(__IPHONE_8_0)
    if ([context respondsToSelector:@selector(setName:)]) {
        context.name = @"Core Node";
    }
#endif

    // You could also just make this something directly on your filesystem in your source repo
    NSURL *rootUrl = [[NSBundle mainBundle] resourceURL];

    // By using "" as our base filepath, we'll use index.js to get started which is a reasonable default
    // Note that we had to add index.js to this project and give it target membership in REPL, so that
    // it is copied into the budnle, since we use the bundle resourceURL for our rootUrl (see above)
    NSURL *mainScriptUrl = [CNRuntime urlWithBase:rootUrl filePath:@""];

    // Setup the CNRuntime
    _runtime = [[CNRuntime alloc] initWithContext:context rootUrl:rootUrl];

    // There's a soft convention in Node to set NODE_ENV to 'development' or 'production'
    // and so we'll do that here based on whether the debug flag is set
#if defined(DEBUG)
    setenv("NODE_ENV", "development", 1);
#else
    setenv("NODE_ENV", "production", 1);
#endif

    // Install Node
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
    _inputTextView.text = nil;
}

- (void)_evalButtonTapped:(UIButton *)sender {

    JSContext *context = _runtime.context;
    NSString *script = _inputTextView.text;

    // This is how to evaluate an arbitrary string of JavaScript
    JSValue *result = [CNRuntime evaluateCallbackScript:script inContext:context];

    // If we have an Exception/Error, we'll display it (& a trace) in red
    if (context.exception) {

        NSString *exceptionText = [context.exception errorString];
        _outputTextView.textColor = [UIColor redColor];
        _outputTextView.text = exceptionText;

        // We've handled the exception, so set it to nil here, so other things don't try to
        // also handle it
        _runtime.context.exception = nil;

    } else {

        // It would be reasonable to just use `[result toString]` and show that as our output,
        // but the Node REPL uses the `util.inspect` function, so we'll use it here as well.
        // This also shows how we can use `require` within CoreNode
        JSValue *util = [CNRuntime evaluateCallbackScript:@"require('util')" inContext:context];
        NSString *inspectedResult = [[util invokeMethod:@"inspect" withArguments:@[result]] toString];
        _outputTextView.textColor = [UIColor darkTextColor];
        _outputTextView.text = inspectedResult;

        // We'll store the most recent result in the global vairable `_`, so you can conviently use
        // the results of the last line evaluated in the next thing you do when using the REPL
        _runtime.context[@"_"] = result;
    }


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
