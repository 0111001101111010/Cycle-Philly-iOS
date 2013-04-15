/** Cycle Atlanta, Copyright 2012, 2013 Georgia Institute of Technology
 *                                    Atlanta, GA. USA
 *
 *   @author Christopher Le Dantec <ledantec@gatech.edu>
 *   @author Anhong Guo <guoanhong@gatech.edu>
 *
 *   Cycle Atlanta is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   Cycle Atlanta is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Cycle Atlanta.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "FetchUser.h"
#import "constants.h"
#import "CycleAtlantaAppDelegate.h"
#import "PersonalInfoViewController.h"

@implementation FetchUser

@synthesize managedObjectContext, receivedData, parent, deviceUniqueIdHash, activityDelegate, alertDelegate, activityIndicator, uploadingView, user, urlRequest;


- (void)reloadUser{
    self.managedObjectContext = [(CycleAtlantaAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest		*request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext];
    
	[request setEntity:entity];
	
	NSError *error;
	
	NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"no saved user");
		if ( error != nil )
			NSLog(@"Fetch User fetch error %@, %@", error, [error localizedDescription]);
	}
	
	[self setUser:[mutableFetchResults objectAtIndex:0]];
    
    if ( user != nil ){
        NSLog(@"User HomeZIP Pre: %@", user.homeZIP );
        //user.homeZIP = @"33333";
        [user setHomeZIP:@"33333"];
    }

    NSLog(@"User HomeZIP Post: %@", user.homeZIP );
    [self.managedObjectContext save:&error ];
//    user.homeZIP = @"33333";
    
	[mutableFetchResults release];
	[request release];
}

//after fetching user and trips, send data back to PersonalInfoViewController and TripManager to add into the db

- (void)fetchUserAndTrip{
    CycleAtlantaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    //TODO reset to delegate.uniqueIDHash for production. 
    self.deviceUniqueIdHash = @"2ecc2e36c3e1a512d349f9b407fb281e";// delegate.uniqueIDHash;
    NSLog(@"start downloading");
    NSLog(@"DeviceUniqueIdHash: %@", deviceUniqueIdHash);
    [self reloadUser];
    
    NSDictionary *fetchDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"get_user_and_trips", @"t", deviceUniqueIdHash, @"d", nil];
    
    NSMutableString *postBody = [NSMutableString string];
    NSString *sep = @"";
    for(NSString * key in fetchDict) {
        [postBody appendString:[NSString stringWithFormat:@"%@%@=%@",
                                sep,
                                key,
                                [fetchDict objectForKey:key]]];
        sep = @"&";
    }
    
    NSData *postData = [postBody dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"POST Data: %@", postBody);
    
    self.urlRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    [urlRequest setURL:[NSURL URLWithString:kFetchURL]];

    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody:postData];
	
	// create the connection with the request and start loading the data
	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	
    // create loading view to indicate trip is being uploaded
    //uploadingView = [[LoadingView loadingViewInView:parent.parentViewController.view messageString:kDownloadingUser] retain];
    
    if ( theConnection )
    {
        receivedData=[[NSMutableData data] retain];
    }
    else
    {
        // inform the user that the download could not be made
        NSLog(@"Download failed!");
        
    }
}

#pragma mark NSURLConnection delegate methods


- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	NSLog(@"%d bytesWritten, %d totalBytesWritten, %d totalBytesExpectedToWrite",
		  bytesWritten, totalBytesWritten, totalBytesExpectedToWrite );
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	NSLog(@"didReceiveResponse: %@", response);
	
	NSHTTPURLResponse *httpResponse = nil;
	if ( [response isKindOfClass:[NSHTTPURLResponse class]] &&
		( httpResponse = (NSHTTPURLResponse*)response ) )
	{
		BOOL success = NO;
		NSString *title   = nil;
		NSString *message = nil;
		switch ( [httpResponse statusCode] )
		{
			case 200:
			case 201:
				success = YES;
				title	= kSuccessFetchTitle;
				message = kFetchSuccess;
				break;
			case 500:
			default:
				title = @"Internal Server Error";
				message = kServerError;
		}
		
		NSLog(@"%@: %@", title, message);
        
        // DEBUG
        NSLog(@"+++++++DEBUG didReceiveResponse %@: %@", [response URL],[(NSHTTPURLResponse*)response allHeaderFields]);
        
        if ( success )
		{
            NSLog(@"Download Success!!!");
			NSError *error;
			if (![managedObjectContext save:&error]) {
				// Handle the error.
				NSLog(@"FetchUser error %@, %@", error, [error localizedDescription]);
			}
            
            //[uploadingView loadingComplete:kSuccessTitle delayInterval:.7];
		} else {
            
            //[uploadingView loadingComplete:kServerError delayInterval:1.5];
        }
	}
	
    // it can be called multiple times, for example in the case of a
	// redirect, so each time we reset the data.
	
    // receivedData is declared as a method instance elsewhere
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
	[receivedData appendData:data];
    //	[activityDelegate startAnimating];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
	
    // receivedData is declared as a method instance elsewhere
    [receivedData release];
    
    // TODO: is this really adequate...?
    [uploadingView loadingComplete:kConnectionError delayInterval:1.5];
    
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// do something with the data
    NSLog(@"+++++++DEBUG: Received %d bytes of data", [receivedData length]);
	NSLog(@"%@", [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease] );
    
    // release the connection, and the data object
    [connection release];
    [receivedData release];
}

@end
