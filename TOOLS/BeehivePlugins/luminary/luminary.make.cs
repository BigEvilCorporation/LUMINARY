using Sharpmake;

[Generate]
class Luminary : IonLib
{
    public Luminary() : base("luminary")
    {
        AddTargets(Globals.IonTargetsDefault);
    }

    [Configure]
    public override void Configure(Project.Configuration conf, Target target)
    {
        base.Configure(conf, target);
    }
}