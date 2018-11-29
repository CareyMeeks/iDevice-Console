//
//  NIFSyslogOutput.m
//  iDevice Console
//
//  Created by Terry Lewis on 30/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFSyslogOutput.h"
#import <AppKit/AppKit.h>
#import "NIFConsoleSettingsManager.h"

@implementation NIFSyslogOutput{
    NSMutableAttributedString *_attributedMessage;
    NSString *_processName;
    NSString *_processAndPIDString;
    BOOL _hasLoadedProcessInfo;
}

+ (instancetype)outputWithDevice:(AMDevice *)device message:(NSString *)message{
    return [[NIFSyslogOutput alloc] initWithDevice:device message:message];
}

- (NSString *)cleanedMessageString:(NSString *)message{
    char lastChar = [message characterAtIndex:message.length-1];
    if (lastChar == '\n' || lastChar == '\r') {
        NSMutableString *string = [NSMutableString stringWithString:message];
        [string deleteCharactersInRange:NSMakeRange([string length]-1, 1)];
        return string;
    }
    return message;
}

- (instancetype)initWithDevice:(AMDevice *)device message:(NSString *)message{
    if (self = [super init]) {
        _isMarker = NO;
        _device = device;
        _message = [self cleanedMessageString:message];
    }
    return self;
}

- (NSMutableAttributedString *)attributedMessage{
    if (!_attributedMessage) {
        _attributedMessage = [self attributedMessageFromMessage:_message];
    }
    return _attributedMessage;
}

- (NSString *)processAndPIDString{
    if (!_processAndPIDString) {
        [self _loadProcessNameInfo];
    }
    return _processAndPIDString;
}

- (NSString *)processName{
    if (!_processName) {
        [self _loadProcessNameInfo];
    }
    return _processName;
}

- (int)obtainSpaceOffsetsInOutput:(NSString *)string output:(size_t *)space_offsets_out{
    const char *buffer = string.UTF8String;
    NSInteger length = string.length + 1;
    int offsetCount = 0;
    for (size_t i = 16; i < length; i++) {
        if (buffer[i] == ' ') {
            space_offsets_out[offsetCount++] = i;
            if (offsetCount == 3) {
                break;
            }
        }
    }
    return offsetCount;
}

- (NSString *)processNameFromProcessNameWithPID:(NSString *)processNameWithPID{
    char *processName = malloc(_processAndPIDString.length + 1);
    strncpy(processName, processNameWithPID.UTF8String, processNameWithPID.length + 1);
    
    for (unsigned long i = strlen(processName); i != 0; i--){
        if (processName[i] == '['){
            processName[i] = '\0';
            break;
        }
    }
    NSString *processString = [[NSString alloc] initWithUTF8String:processName];
    free(processName);
    return processString;
}

- (BOOL)range:(NSRange)range validForString:(NSString *)string{
    NSUInteger rangeEnd = (range.location + range.length - 1);
    NSUInteger strLen = string.length;
    if (range.location - 1 > strLen || rangeEnd > strLen) {
//        NSLog(@"%li %li %li", range.location, rangeEnd, strLen);
        return NO;
    }
    return YES;
}

- (void)_loadProcessNameInfo{
    if (_hasLoadedProcessInfo) {
        return;
    }
    _hasLoadedProcessInfo = YES;
    if (!_processAndPIDString) {
        
        size_t space_offsets[3];
        [self obtainSpaceOffsetsInOutput:self.message output:space_offsets];
        unsigned long long nameLength = space_offsets[1] - space_offsets[0]; //This size includes the NULL terminator.
        NSRange nameRange = NSMakeRange(space_offsets[0]+1, nameLength);
        if ([self range:nameRange validForString:self.message]) {
            _processAndPIDString = [self.message substringWithRange:nameRange];
        }else{
            
        }
    }
    if (_processAndPIDString) {
        _processName = [self processNameFromProcessNameWithPID:_processAndPIDString];
    }
}

- (void)_addAttributesToAttributedString:(NSMutableAttributedString *)attributed{
    [attributed addAttribute:NSFontAttributeName value:[[NIFConsoleSettingsManager sharedManager] font] range:NSMakeRange(0, attributed.length)];
    if ([self processAndPIDString]) {
        NSRange nameRange = [self.message rangeOfString:[self processName]];
        [attributed addAttribute:NSFontAttributeName value:[[NIFConsoleSettingsManager sharedManager] boldFont] range:nameRange];
    }
}

- (NSMutableAttributedString *)attributedMessageFromMessage:(NSString *)message{
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:message];
    [self _addAttributesToAttributedString:attributed];
    
    return attributed;
}

- (instancetype)initWithMarkerForDevice:(AMDevice *)device{
    if (self = [super init]) {
        _isMarker = YES;
        _device = device;
        NSMutableAttributedString *marker = [NIFSyslogOutput markerAttributedStringForCurrentDate];
        _attributedMessage = marker;
        _message = marker.string;
    }
    return self;
}

+ (instancetype)markerForDevice:(AMDevice *)device{
    return [[NIFSyslogOutput alloc] initWithMarkerForDevice:device];
}

+ (NSMutableAttributedString *)attributedStringFromString:(NSString *)string{
    return [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName : [[NIFConsoleSettingsManager sharedManager] font]}];
}

+ (NSString *)formattedCurrentDate{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd/MM/yyyy HH:mm:ss.SSS"];
        formatter.timeZone = [NSTimeZone systemTimeZone];
    });
    NSDate *date = [NSDate date];
    return [formatter stringFromDate:date];
}

+ (NSMutableAttributedString *)markerAttributedStringForCurrentDate{
    //    24/11/2015 11:11:37.233 PM Console[20813]:  Marker - 24 Nov 2015, 11:11:37 PM
    NSString *string = [NSString stringWithFormat:@"Marker - %@", [NIFSyslogOutput formattedCurrentDate]];
    return [NIFSyslogOutput attributedStringFromString:string];
}

- (void)changeFont:(id)sender{
    if (!_attributedMessage) {
        return;
    }
    [self _addAttributesToAttributedString:_attributedMessage];
//    [_attributedMessage enumerateAttributesInRange:NSMakeRange(0, _attributedMessage.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
////        NSLog(@"Attributes: %@\nRange: %@", attrs, NSStringFromRange(range));
//        if ([attrs objectForKey:NSFontAttributeName] == font) {
//            [_attributedMessage addAttribute:NSFontAttributeName value:[NIFConsoleSettingsManager font] range:range];
//        }else if([attrs objectForKey:NSFontAttributeName] == font){
//            [_attributedMessage addAttribute:NSFontAttributeName value:[NIFConsoleSettingsManager boldFont] range:range];
//        }
//    }];
}

//- (id)copyWithZone:(NSZone *)zone{
//    return self;
//}

@end
