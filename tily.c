const char *class, *instance;
unsigned int i;
const Rule *r;
Monitor *m;
XClassHint ch = { NULL, NULL };

/* Rule matching */
c->isfloating = 0;
c->tags = 0;
XGetClassHint(dpy, c->win, &ch);

/* Assign class and instance values, handling NULL cases */
class = ch.res_class ? ch.res_class : "broken";
instance = ch.res_name ? ch.res_name : "broken";

for (i = 0; i < LENGTH(rules); i++) {
    r = &rules[i];

    if ((!r->title || strstr(c->name, r->title)) &&
        (!r->class || strstr(class, r->class)) &&
        (!r->instance || strstr(instance, r->instance)))
    {
        c->isfloating = r->isfloating;
        c->tags |= r->tags;

        for (m = mons; m && m->num != r->monitor; m = m->next)
            ; /* Iterate through monitors until the correct one is found */

        if (m)
            c->mon = m;
    }
}
