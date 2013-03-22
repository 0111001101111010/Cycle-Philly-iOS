//
//  DetailViewController.m
//  Cycle Atlanta
//
//  Created by Guo Anhong on 12-11-8.
//
//

#import "DetailViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "NoteManager.h"

@interface DetailViewController ()
static UIImage *shrinkImage(UIImage *original, CGSize size);

- (void)updateDisplay;
- (void)getMediaFromSource:(UIImagePickerControllerSourceType)sourceType;
@end

@implementation DetailViewController
@synthesize delegate;
@synthesize detailTextView;
@synthesize addPicButton;
@synthesize imageView;
@synthesize image;
@synthesize imageFrame;
@synthesize imageFrameView;
@synthesize lastChosenMediaType;
@synthesize imageData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    //[self.detailTextView setText:@"Enter More Details Here"];
    [self.detailTextView becomeFirstResponder];
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if (![UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera]) {
        addPicButton.hidden = YES;
    }
    
    detailTextView.layer.borderWidth = 1.0;
    detailTextView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.imageFrame = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"photoFrame" ofType:@"png"]];
    imageFrameView.image = imageFrame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateDisplay];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


-(IBAction)skip:(id)sender{
    NSLog(@"Skip");
    [delegate didCancelNote];
    
    pickerCategory = [[NSUserDefaults standardUserDefaults] integerForKey:@"pickerCategory"];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey: @"pickerCategory"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    details = @"";
    image = nil;
    
    [delegate didEnterNoteDetails:details];
    [delegate didSaveImage:nil];
    [delegate saveNote];
}

-(IBAction)saveDetail:(id)sender{
    NSLog(@"Save Detail");
    [detailTextView resignFirstResponder];
    [delegate didCancelNote];
    
    pickerCategory = [[NSUserDefaults standardUserDefaults] integerForKey:@"pickerCategory"];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey: @"pickerCategory"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    details = detailTextView.text;
    
    [delegate didEnterNoteDetails:details];
    [delegate didSaveImage:imageData];
    [delegate saveNote];
}

- (IBAction)shootPictureOrVideo:(id)sender {
    [self getMediaFromSource:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)selectExistingPictureOrVideo:(id)sender {
    [self getMediaFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    self.imageFrameView = nil;
    [imageFrameView release];
}

#pragma mark UIImagePickerController delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //original
    UIImage *castedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    //save to library
    UIImageWriteToSavedPhotosAlbum(castedImage,self, nil, nil);
    
    CGSize size;
    
    if (castedImage.size.height > castedImage.size.width) {
        size.height = 1080;
        size.width = 810;
    }
    else {
        size.height = 810;
        size.width = 1080;
    }
    
    UIGraphicsBeginImageContext(size);
    [castedImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(destImage, 1)];
    
    NSLog(@"Size of Image(bytes):%d",[imageData length]);
    
    self.image = castedImage;

    [picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark  -
static UIImage *shrinkImage(UIImage *original, CGSize size) {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(NULL, size.width * scale,
                                                 size.height * scale, 8, 0, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context,
                       CGRectMake(0, 0, size.width * scale, size.height * scale),
                       original.CGImage);
    CGImageRef shrunken = CGBitmapContextCreateImage(context);
    UIImage *final = [UIImage imageWithCGImage:shrunken];
    
    CGContextRelease(context);
    CGImageRelease(shrunken);
    CGColorSpaceRelease(colorSpace);
    return final;
}

- (void)updateDisplay {
    imageView.image = image;
    imageView.hidden = NO;
}

- (void)getMediaFromSource:(UIImagePickerControllerSourceType)sourceType {
    //NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    if ([UIImagePickerController isSourceTypeAvailable:
         sourceType]) {
        //NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        //picker.mediaTypes = mediaTypes;
        //picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        picker.delegate = self;
        picker.sourceType = sourceType;
        [self presentModalViewController:picker animated:YES];
        [picker release];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error accessing media"
                              message:@"Device doesn’t support that media source."
                              delegate:nil
                              cancelButtonTitle:@"Drat!"
                              otherButtonTitles:nil];
        [alert show];
    }
}


- (void)dealloc {
    self.delegate = nil;
    self.detailTextView = nil;
    self.addPicButton = nil;
    self.imageView = nil;
    self.imageFrameView = nil;
    self.image = nil;
    self.imageFrame = nil;
    self.imageData = nil;
    self.lastChosenMediaType = nil;
    
    [delegate release];
    [detailTextView release];
    [addPicButton release];
    [imageView release];
    [imageFrameView release];
    [image release];
    [imageFrame release];
    [imageData release];
    [lastChosenMediaType release];
    
    [super dealloc];
}


@end
