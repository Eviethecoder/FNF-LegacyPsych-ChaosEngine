function oncreate()
{
	this.ignoreNote = mustPress;
	this.lowPriority = true;
	if (this.isSustainNote)
	{
		this.missHealth = 0.1;
	}
	else
	{
		this.missHealth = 0.3;
	}
	this.hitCausesMiss = true;
}
