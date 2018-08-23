@interface EPCDraggableRotaryNumberView : UIView {
	UIPanGestureRecognizer *panRec;
	UILabel* _label;
}
@property (nonatomic, strong) UIPanGestureRecognizer* panRec;
@property (nonatomic, retain, readonly) NSString* character;
@property (nonatomic, retain, readonly) NSString* displayableCharacter;
-(id)initWithDefaultSizeWithCharacter:(NSString*)character;
-(void)updateNumberLabel;
-(CALayer*)outlineLayer;
@end