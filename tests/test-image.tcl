set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
set fix [file join $base tests fixtures]
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set png [file join $fix odt-lib-volltest-bild1.png]
set jpg [file join $fix test640.jpg]

# ---- A) embed from file + options + frame style ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t defineFrameStyle Float -wrap parallel -hpos right -hrel paragraph \
    -border "0.5pt solid #888888" -padding 0.1cm
set href [$t embedImage $png -name logo]
ok {$href eq "Pictures/logo.png"}                              "A: embedImage returns Pictures href"
ok {[$pkg has $href]}                                          "A: image bytes embedded in package"
ok {[string match "*image/png*" [encoding convertfrom utf-8 [$pkg part META-INF/manifest.xml]]]} "A: manifest media-type png"
# place the embedded one centered with alt text
$t appendImageFit $href -name logo -maxwidth 5cm -align center -title "Logo" -desc "Company logo"
# embed+place a second image, floating with a frame style, char-anchored
$t appendImageFile $jpg -name photo -maxwidth 6cm -anchor char -style Float

ok {[lsort [$t images]] eq {logo photo}}                       "A: images listed"
set li [$t imageInfo logo]
ok {[dict get $li title] eq "Logo"}                            "A: logo title (alt text)"
ok {[dict get $li desc] eq "Company logo"}                     "A: logo desc (alt text)"
ok {[dict get $li anchor] eq "as-char"}                        "A: logo anchor as-char (for centering)"
set pi [$t imageInfo photo]
ok {[dict get $pi anchor] eq "char"}                           "A: photo anchor char"
ok {[dict get $pi style] eq "Float"}                           "A: photo uses frame style"
# the centered image's paragraph references an alignment style
$t flush
set cd [$pkg tree content.xml]; set root [$cd documentElement]
set logoFr ""
foreach fr [$root getElementsByTagName draw:frame] { if {[$fr getAttribute draw:name ""] eq "logo"} { set logoFr $fr; break } }
ok {[[$logoFr parentNode] getAttribute text:style-name ""] eq "ImgAlignCenter"} "A: centered image paragraph style"
ok {[llength [$root getElementsByTagName style:graphic-properties]] >= 1}        "A: graphic style present"
set fs ""; foreach st [$root getElementsByTagName style:style] { if {[$st getAttribute style:name ""] eq "Float"} { set fs $st } }
ok {[[lindex [$fs getElementsByTagName style:graphic-properties] 0] getAttribute style:wrap ""] eq "parallel"} "A: frame style wrap=parallel"
# 0.38 regression: ODF 1.3 RNG requires the frame content (draw:image) BEFORE
# svg:title/svg:desc; emitting title/desc first makes odfvalidator reject the frame.
set kids {}
foreach c [$logoFr childNodes] { if {[$c nodeType] eq "ELEMENT_NODE"} { lappend kids [$c nodeName] } }
ok {[lindex $kids 0] eq "draw:image"}                                        "A: draw:image is first frame child (RNG order)"
ok {[lsearch -exact $kids draw:image] < [lsearch -exact $kids svg:title]}    "A: draw:image precedes svg:title"
ok {[lsearch -exact $kids svg:title] < [lsearch -exact $kids svg:desc]}      "A: svg:title precedes svg:desc"
$cd delete
$t destroy
# write to a test-specific name so it does not clobber examples/demo-image.tcl's out/image.odt
$pkg save [file join $out image-test.odt]; $pkg destroy

# ---- B) reload: images + alt text persist ----
set pkg2 [odf::Package new [file join $out image-test.odt]]
set t2   [odf::Text new $pkg2]
ok {[lsort [$t2 images]] eq {logo photo}}                      "B: images persisted"
ok {[dict get [$t2 imageInfo logo] desc] eq "Company logo"}    "B: alt text persisted"
ok {[$pkg2 has Pictures/logo.png]}                             "B: image part persisted"
$t2 destroy; $pkg2 destroy

# ---- C) error cases ----
set pkg3 [odf::newTextDoc]; set t3 [odf::Text new $pkg3]
ok {[catch {$t3 embedImage /no/such/file.png}]}                "C: missing file -> error"
ok {[catch {$t3 appendImageFit Pictures/none.png}]}            "C: missing part -> error"
ok {[catch {$t3 defineFrameStyle X -bogus 1}]}                 "C: unknown frame option -> error"
ok {[catch {$t3 appendImageFit Pictures/none.png -align middle}]} "C: bad align -> error (or missing part)"
$t3 destroy; $pkg3 destroy

# ---- D) more image formats: WebP / TIFF / BMP / SVG (text 0.23) ----
proc writeb {path bytes} { set f [open $path wb]; puts -nonewline $f $bytes; close $f }
set pkgF [odf::newTextDoc]; set tF [odf::Text new $pkgF]
set wp [file join $out s.webp]; writeb $wp "RIFF\x24\x00\x00\x00WEBPVP8 fakewebp"
set tf [file join $out s.tif];  writeb $tf "II\x2A\x00\x08\x00\x00\x00faketiff"
set bm [file join $out s.bmp];  writeb $bm "BM\x46\x00\x00\x00fakebmpdata"
set sv [file join $out s.svg];  writeb $sv "<?xml version=\"1.0\"?>\n<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"10\" height=\"10\"><rect width=\"10\" height=\"10\"/></svg>"
ok {[$tF embedImage $wp -name w] eq "Pictures/w.webp"}    "D: webp sniff -> .webp"
ok {[$tF embedImage $tf -name t] eq "Pictures/t.tif"}     "D: tiff sniff -> .tif"
ok {[$tF embedImage $bm -name b] eq "Pictures/b.bmp"}     "D: bmp sniff -> .bmp"
ok {[$tF embedImage $sv -name v] eq "Pictures/v.svg"}     "D: svg sniff -> .svg"
set man [encoding convertfrom utf-8 [$pkgF part META-INF/manifest.xml]]
ok {[string match "*image/webp*" $man]}                   "D: manifest webp"
ok {[string match "*image/tiff*" $man]}                   "D: manifest tiff"
ok {[string match "*image/bmp*" $man]}                    "D: manifest bmp"
ok {[string match "*image/svg+xml*" $man]}                "D: manifest svg+xml"
# unknown bytes still rejected (no fallback)
set xx [file join $out s.dat]; writeb $xx "not an image at all"
ok {[catch {$tF embedImage $xx -name x}]}                 "D: unknown bytes -> error"
$tF destroy; $pkgF destroy

# ---- E) captioned images (text 0.25) ----
set pkgC [odf::newTextDoc]; set tC [odf::Text new $pkgC]
set hrefC [$tC embedImage $png -name fig1]
set fr [$tC appendCaptionedImage $hrefC 6cm 4cm "Figure 1: the company logo" -name fig1]
ok {[$fr nodeName] eq "draw:frame"}                       "E: returns outer frame"
ok {[$fr getAttribute svg:height ""] eq ""}               "E: outer frame omits height (auto-grow)"
ok {[$tC captionText $fr] eq "Figure 1: the company logo"} "E: caption text (pre-save)"
ok {[$tC captionImage $fr] eq $hrefC}                     "E: image href in caption frame"
ok {[catch {$tC appendCaptionedImage $hrefC 6cm 4cm cap -bogus 1}]} "E: unknown option rejected"
ok {[catch {$tC appendCaptionedImage Pictures/none.png 6cm 4cm cap}]} "E: missing part rejected"
$tC flush
set odtC [file join $out caption.odt]; $pkgC save $odtC
$tC destroy; $pkgC destroy

set pkgC2 [odf::Package new $odtC]; set tC2 [odf::Text new $pkgC2]
set frames [$tC2 captionFrames]
ok {[llength $frames] == 1}                               "E: one caption frame found"
ok {[$tC2 captionText [lindex $frames 0]] eq "Figure 1: the company logo"} "E: caption persisted"
ok {[$tC2 captionImage [lindex $frames 0]] eq "Pictures/fig1.png"} "E: image href persisted"
ok {![catch {dom parse [encoding convertfrom utf-8 [$pkgC2 part content.xml]] dd}]} "E: content.xml well-formed"
catch {dd delete}
$tC2 destroy; $pkgC2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
