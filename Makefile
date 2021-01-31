OUTDIR  = stl
IMGDIR  = img
MODULES = \
	base_shaft \
	washer \
	crank_washer \
	guide_top \
	guide_bottom \
	base_crank \
	shaft \
	gears_support \
	small_gear \
	pole \
	big_gear \
	crank \
	all

STLS  = $(addprefix $(OUTDIR)/,$(addsuffix .stl,$(MODULES)))
IMGS  = $(addprefix $(IMGDIR)/,$(addsuffix .png,$(MODULES)))
IMGS += $(addprefix $(IMGDIR)/,$(addsuffix _cross.png,$(MODULES)))

.PHONY: all stls images guide_length clean

all: stls

images: $(IMGS)
stls:   $(STLS)

guide_length:
	@openscad \
		--preview=throwntogether \
		-D module_name=\"guide\" \
		-o .deleteme.png \
		winder.scad \
	2>&1 | grep "Guide rod lenght"
	@-rm -f .deleteme.png

$(OUTDIR)/%.stl: winder.scad | $(OUTDIR)
	openscad --render -D module_name=\"$(basename $(@F))\" -o "$@" "$<"

CROSS_SECTION=false
$(IMGDIR)/%_cross.png: CROSS_SECTION=true
$(IMGDIR)/%_cross.png: winder.scad | $(IMGDIR)
$(IMGDIR)/%.png: winder.scad | $(IMGDIR)
	mn_cross=$(basename $(@F)) && \
	openscad \
		--autocenter \
		--viewall \
		--projection=ortho \
		-D module_name=\"$${mn_cross/_cross/}\" \
		-D cross_section=$(CROSS_SECTION) \
		-o "$@" "$<"

$(OUTDIR) $(IMGDIR):
	mkdir -p "$@"

clean:
	@-rm -frv $(OUTDIR)
	@-rm -frv $(IMGDIR)
