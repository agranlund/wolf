; Filename: gbc_only.bmp
; Pixel Width: 160px
; Pixel Height: 144px

.EQU gbc_only_tile_map_size 	$0168
.EQU gbc_only_tile_map_width 	$14
.EQU gbc_only_tile_map_height 	$12

.EQU gbc_only_tile_data_size 	$07F0
.EQU gbc_only_tile_count 	$0168

; ////////////////
; //            //
; //  Map Data  //
; //            //
; ////////////////

gbc_only_map_data:
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$01,$02,$03,$04
.DB $05,$06,$07,$08,$01,$02,$03,$04,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10
.DB $11,$12,$13,$14,$0D,$0E,$0F,$10,$09,$0A,$0B,$0C,$15,$16,$17,$18
.DB $19,$1A,$1B,$1C,$1D,$1E,$1F,$20,$19,$1A,$1B,$1C,$15,$16,$17,$18
.DB $21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$25,$26,$27,$28
.DB $21,$22,$23,$24,$2D,$2E,$2F,$30,$31,$32,$33,$34,$35,$36,$37,$38
.DB $31,$32,$33,$34,$2D,$2E,$2F,$30,$39,$3A,$3B,$3C,$3D,$3E,$3F,$40
.DB $41,$42,$43,$44,$3D,$3E,$3F,$40,$39,$3A,$3B,$3C,$45,$46,$47,$48
.DB $49,$4A,$4B,$4C,$4D,$4E,$4F,$50,$49,$4A,$4B,$4C,$45,$46,$47,$48
.DB $51,$52,$53,$54,$55,$56,$57,$58,$51,$52,$53,$54,$55,$56,$57,$58
.DB $51,$52,$53,$54,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$59,$5A,$5B,$5C,$5D,$5E,$5F
.DB $60,$61,$62,$63,$64,$65,$5E,$66,$67,$68,$69,$00,$00,$6A,$6B,$6C
.DB $6D,$6E,$6F,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$7C,$7D,$00,$00,$00,$00,$00
.DB $00,$7E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00

; /////////////////
; //             //
; //  Tile Data  //
; //             //
; /////////////////

gbc_only_tile_data:
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $FF,$FF,$00,$00,$02,$00,$B7,$00,$BF,$40,$FC,$03,$DD,$22,$00,$FF
.DB $FF,$FF,$00,$00,$1B,$24,$37,$48,$DA,$25,$36,$C9,$C0,$3F,$04,$FB
.DB $FF,$FF,$03,$00,$40,$BF,$55,$AA,$3C,$C3,$CA,$35,$5A,$A5,$00,$FF
.DB $FF,$FF,$BF,$7F,$F8,$7F,$78,$FC,$78,$FC,$F9,$FC,$F9,$FC,$F9,$FC
.DB $FF,$FF,$FF,$FF,$03,$FF,$0E,$01,$E0,$00,$AE,$51,$51,$AE,$AC,$53
.DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$00,$55,$AA,$3D,$C2,$B3,$4C
.DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$0C,$03,$FC,$03,$F8,$07,$D7,$2B
.DB $FF,$FF,$E0,$E0,$E1,$E0,$E6,$E0,$E7,$E0,$EF,$E0,$FD,$E2,$F0,$EF
.DB $FF,$FF,$FF,$FF,$FF,$FF,$C3,$FC,$00,$00,$FF,$00,$0B,$F4,$D6,$29
.DB $FF,$FF,$FF,$FF,$FF,$FF,$16,$0E,$F6,$0E,$A6,$5E,$F6,$0E,$A6,$5E
.DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$40,$00,$B5,$0A,$E0,$1F,$4A,$B5
.DB $F8,$FC,$FE,$FC,$FF,$FC,$5E,$3D,$BC,$7F,$3F,$FF,$7F,$FF,$FF,$7F
.DB $4A,$B5,$1E,$E1,$50,$AF,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $AC,$53,$5A,$A5,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $FB,$07,$07,$FF,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $EF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$80,$E0,$9F,$C0,$96,$C9,$AD,$D2
.DB $FF,$FF,$FF,$FF,$FF,$FF,$C3,$FC,$00,$00,$FF,$00,$0B,$F4,$00,$00
.DB $FF,$FF,$FF,$FF,$FF,$FF,$16,$0E,$F6,$0E,$A6,$5E,$F6,$0E,$00,$00
.DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$40,$00,$B5,$0A,$E0,$1F,$00,$00
.DB $F8,$FC,$FE,$FC,$FF,$FC,$5E,$3D,$BC,$7F,$3F,$FF,$7F,$FF,$00,$00
.DB $83,$7C,$13,$EC,$42,$BD,$68,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
.DB $96,$6E,$E6,$1E,$A7,$5E,$06,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$00,$00
.DB $9A,$65,$65,$9A,$41,$BF,$1F,$FF,$FF,$FF,$FF,$FF,$78,$87,$06,$01
.DB $69,$F0,$60,$F0,$F3,$E0,$F5,$E2,$F7,$E0,$E7,$F0,$FA,$F5,$F7,$F8
.DB $FF,$00,$00,$00,$EA,$15,$54,$AB,$BA,$45,$41,$BE,$72,$8D,$51,$AE
.DB $FF,$00,$00,$00,$FF,$00,$EB,$14,$90,$6F,$AB,$54,$90,$6F,$21,$DE
.DB $FF,$03,$03,$03,$D7,$2B,$AB,$57,$D7,$2B,$AF,$57,$47,$BF,$07,$FF
.DB $F9,$C6,$D4,$EB,$DB,$E4,$F8,$E7,$FF,$FF,$FF,$FF,$FF,$FF,$00,$80
.DB $3F,$3F,$6E,$6E,$45,$55,$54,$55,$41,$45,$44,$56,$7F,$7F,$7F,$7F
.DB $FF,$FF,$A8,$A8,$A8,$AD,$8D,$AD,$8D,$8D,$8D,$AD,$FF,$FF,$FF,$FF
.DB $FF,$FF,$AA,$AA,$A8,$A8,$80,$A8,$A8,$AA,$82,$CA,$FF,$FF,$FF,$FF
.DB $FC,$FC,$CA,$CA,$AA,$BA,$38,$BA,$AE,$AE,$8A,$CA,$EE,$FE,$FE,$FE
.DB $FF,$00,$B6,$49,$81,$7E,$48,$B7,$01,$FE,$9A,$65,$41,$BE,$B8,$47
.DB $FF,$00,$4B,$B4,$69,$96,$96,$69,$28,$D7,$60,$9F,$15,$EA,$88,$77
.DB $EE,$01,$7D,$83,$8B,$75,$19,$E7,$05,$FB,$23,$DD,$05,$FB,$29,$D7
.DB $F2,$FD,$F8,$FF,$FF,$FF,$FF,$FF,$E0,$FF,$E0,$F0,$E5,$F2,$E7,$F0
.DB $8A,$75,$00,$FF,$FF,$FF,$FF,$FF,$3F,$FF,$00,$00,$02,$01,$FB,$04
.DB $0A,$F5,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$07,$CF,$03,$FF,$03
.DB $37,$CF,$CF,$37,$FF,$FF,$FF,$FF,$FF,$FF,$E7,$FB,$A3,$C3,$CF,$83
.DB $7F,$80,$71,$8E,$4A,$B5,$41,$BE,$83,$FC,$90,$EF,$8C,$F3,$C0,$FF
.DB $7F,$7F,$70,$70,$7D,$7F,$62,$62,$77,$7F,$60,$60,$75,$7F,$64,$64
.DB $FF,$FF,$08,$08,$5D,$FF,$20,$20,$75,$FF,$82,$82,$D7,$FF,$0C,$0C
.DB $FF,$FF,$90,$90,$FA,$FF,$A0,$A0,$EA,$FF,$88,$88,$EE,$FF,$10,$10
.DB $FE,$FE,$46,$46,$EE,$FE,$06,$06,$AE,$FE,$46,$46,$EE,$FE,$86,$86
.DB $11,$EE,$AA,$55,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$6F,$1F,$9F,$6F
.DB $15,$EA,$A4,$5B,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$FF,$BF,$C0
.DB $45,$BB,$09,$F7,$57,$AB,$83,$FF,$FF,$FF,$FF,$FF,$01,$FF,$FE,$01
.DB $E6,$F1,$EB,$F4,$ED,$F2,$EB,$F4,$E3,$FE,$FF,$FF,$FF,$FF,$3F,$FF
.DB $33,$CC,$14,$EB,$0B,$F4,$06,$F9,$93,$6C,$FF,$FF,$FF,$FF,$FF,$FF
.DB $23,$DF,$D7,$2F,$2F,$D7,$9F,$67,$4F,$B7,$FF,$FF,$FF,$FF,$FF,$FF
.DB $BB,$85,$B5,$8B,$BB,$85,$B3,$8D,$FF,$FF,$FF,$FF,$80,$80,$8F,$80
.DB $E5,$FA,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$E2,$1D
.DB $7D,$7F,$61,$61,$7B,$7F,$64,$64,$7D,$7F,$7F,$7F,$7E,$7F,$7E,$7E
.DB $5E,$FF,$09,$09,$DF,$FF,$20,$20,$75,$FF,$FF,$FF,$1F,$1F,$27,$6F
.DB $BB,$FF,$40,$40,$EA,$FF,$20,$20,$75,$FF,$FF,$FF,$FF,$FF,$80,$80
.DB $AE,$FE,$26,$26,$BE,$FE,$86,$86,$DE,$FE,$FE,$FE,$FE,$FE,$06,$06
.DB $2F,$DF,$17,$EF,$8F,$7F,$5F,$AF,$4F,$BF,$A7,$5F,$47,$BF,$0F,$FF
.DB $A0,$C0,$AF,$C0,$E8,$C7,$EA,$C5,$D0,$8F,$D6,$89,$D5,$8A,$CC,$83
.DB $01,$00,$FD,$02,$1B,$E4,$16,$E9,$83,$7C,$9E,$61,$56,$A9,$01,$FE
.DB $FE,$01,$01,$00,$FE,$00,$BA,$44,$AE,$51,$BA,$45,$75,$8A,$58,$A7
.DB $00,$FF,$FF,$00,$00,$00,$FF,$00,$51,$AE,$BA,$45,$0D,$F2,$90,$6F
.DB $03,$FF,$FB,$07,$0F,$07,$F7,$0F,$57,$AF,$E7,$1F,$57,$AF,$57,$AF
.DB $BA,$85,$A4,$9B,$BF,$80,$BB,$84,$F4,$8B,$CB,$B4,$F8,$87,$8F,$FC
.DB $11,$EE,$A4,$5B,$43,$BC,$50,$AF,$AA,$55,$E8,$17,$14,$EB,$49,$B6
.DB $7C,$7D,$7D,$7D,$7C,$7C,$7C,$7E,$7E,$7F,$7F,$7F,$7F,$7F,$3F,$3F
.DB $47,$47,$E7,$F7,$57,$57,$4F,$C7,$1F,$0F,$BF,$FF,$FF,$FF,$FF,$FF
.DB $D5,$FF,$80,$80,$EA,$FF,$CF,$FF,$E0,$E3,$F7,$FF,$FF,$FF,$FF,$FF
.DB $5E,$FE,$06,$06,$AE,$FE,$3E,$FE,$82,$B2,$FE,$FE,$FE,$FE,$FC,$FC
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$0F,$00,$00,$B5,$4A
.DB $82,$CD,$99,$C6,$80,$FF,$FF,$FF,$FF,$FF,$3F,$FF,$7F,$00,$C1,$00
.DB $A4,$5B,$51,$AE,$0B,$F4,$F8,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$78,$F8
.DB $6B,$94,$54,$AB,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
.DB $40,$BF,$04,$FB,$52,$AD,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$00
.DB $87,$7F,$47,$BF,$17,$EF,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$07
.DB $FF,$FF,$FF,$FF,$FF,$FF,$BE,$C1,$E0,$80,$DA,$84,$DF,$80,$D4,$8B
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E7,$1F,$1F,$00,$60,$80,$CA,$35
.DB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$0F,$00,$00,$B5,$4A
.DB $00,$00,$99,$C6,$80,$FF,$FF,$FF,$FF,$FF,$3F,$FF,$7F,$00,$C1,$00
.DB $00,$00,$51,$AE,$0B,$F4,$F8,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$78,$F8
.DB $00,$00,$54,$AB,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
.DB $10,$EF,$8A,$75,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $AE,$51,$AF,$51,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $FF,$F8,$FB,$F8,$FF,$F8,$FF,$F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $F5,$0A,$2E,$D1,$EF,$10,$FB,$04,$F3,$FC,$FF,$FF,$FF,$FF,$FF,$FF
.DB $DA,$25,$B7,$48,$FF,$00,$2E,$D1,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF
.DB $E3,$1F,$53,$AF,$F3,$0F,$AF,$57,$E7,$1F,$FF,$FF,$FF,$FF,$FF,$FF
.DB $DF,$80,$F4,$8B,$DF,$BF,$BF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $59,$A6,$DC,$23,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FB,$F0,$FB,$FD,$FB,$FD,$FB,$FD,$FB,$FD
.DB $FF,$FF,$FF,$FF,$FF,$FF,$1F,$0F,$FF,$CF,$FF,$CF,$BF,$8F,$F8,$88
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$C1
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FC,$F8,$F1,$FB,$F7,$F3,$F7,$F7,$FF,$E7
.DB $FF,$FF,$FF,$FF,$FF,$FF,$7F,$1F,$BF,$1F,$FF,$9F,$FF,$9F,$F0,$98
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F1,$40
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$9C,$0E
.DB $FF,$FF,$FF,$FF,$FF,$FF,$F7,$E3,$FB,$F7,$FF,$F3,$FB,$F7,$1C,$30
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$71
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$81,$11
.DB $FF,$FF,$FF,$FF,$FF,$FF,$F9,$F0,$F3,$E6,$E7,$EF,$DF,$EF,$FF,$CF
.DB $FF,$FF,$FF,$FF,$FF,$FF,$BF,$7F,$7F,$7F,$7F,$7F,$BF,$7F,$B3,$61
.DB $FF,$FF,$FF,$FF,$FF,$FF,$BF,$1F,$FF,$9F,$BF,$DF,$FF,$9F,$BC,$D8
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$F8
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$69,$C0
.DB $FF,$FF,$FF,$FF,$FF,$FF,$CF,$8F,$EF,$EF,$EF,$EF,$EF,$EF,$E1,$E8
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$9F,$0F
.DB $FB,$FD,$F8,$FC,$FB,$FD,$FB,$FD,$FB,$FD,$FB,$FD,$F8,$F0,$FF,$FF
.DB $7F,$B2,$67,$37,$6F,$B7,$FF,$A7,$B7,$B7,$F7,$F2,$F0,$78,$FF,$FF
.DB $77,$64,$F9,$24,$77,$AF,$FF,$27,$F7,$2F,$7F,$67,$47,$C3,$FF,$FF
.DB $FF,$E7,$FF,$E7,$FF,$E7,$EF,$F7,$F3,$F7,$F9,$F3,$FC,$F8,$FF,$FF
.DB $FA,$F3,$0F,$0F,$FF,$9E,$F2,$99,$FF,$97,$B7,$12,$70,$18,$FF,$FF
.DB $70,$66,$6F,$76,$7F,$66,$6F,$76,$3F,$46,$7F,$06,$80,$00,$FF,$FF
.DB $0D,$6C,$EB,$6D,$78,$EC,$7F,$E9,$7F,$ED,$75,$EC,$44,$02,$FF,$FF
.DB $98,$D3,$EF,$D3,$0B,$17,$FF,$F3,$EF,$D3,$D8,$93,$1C,$30,$FF,$FF
.DB $0F,$64,$FF,$0E,$7F,$8E,$6F,$9E,$FE,$0E,$2F,$64,$E0,$71,$FF,$FE
.DB $FB,$BB,$57,$BB,$BB,$57,$77,$D7,$6F,$D7,$FF,$C7,$CF,$EF,$7F,$4F
.DB $FF,$CF,$FF,$CF,$FF,$CF,$EF,$EF,$E7,$EF,$F3,$E6,$F8,$F0,$FF,$FF
.DB $C5,$EC,$FE,$CE,$1E,$DE,$DE,$1E,$BC,$4E,$45,$6C,$73,$E1,$FF,$FF
.DB $FA,$93,$B7,$D7,$F7,$97,$B7,$D7,$F7,$97,$BA,$D3,$88,$08,$FF,$FF
.DB $31,$66,$6D,$B4,$BF,$A7,$AF,$B7,$FF,$27,$2F,$77,$E3,$43,$FF,$FF
.DB $FF,$F2,$E7,$F7,$EF,$F7,$FF,$E7,$F7,$F7,$F7,$F2,$F0,$F8,$FF,$FF
.DB $72,$66,$FF,$26,$77,$AE,$F7,$2E,$F7,$2E,$77,$6E,$44,$C0,$FF,$FF
.DB $6D,$EB,$6B,$ED,$EF,$6D,$6F,$ED,$ED,$6E,$EF,$6E,$03,$06,$F6,$F2
.DB $FF,$9F,$DF,$BF,$7F,$BF,$FF,$3F,$BF,$7F,$7F,$7F,$FF,$7F,$7F,$FF
.DB $FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $5F,$4F,$3F,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.DB $F6,$F0,$F8,$F1,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
