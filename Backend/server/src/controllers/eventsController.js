const Event = require('../models/Event');
const { uploadImage } = require('../services/cloudinaryService');

class EventsController {
  /**
   * Add a new event (Admin/Super-admin only)
   */
  addEvent = async (req, res, next) => {
    try {
      console.log('--- Incoming Add Event Request ---');
      let body = this._parseEventBody(req.body);

      // If files are uploaded, upload them to Cloudinary
      if (req.files && req.files.length > 0) {
        console.log(`Uploading ${req.files.length} images...`);
        // Sanitize folder name: remove special chars, keep alphanumeric and underscores
        const safeTitle = String(body.title || 'unnamed')
          .trim()
          .replace(/[^\w\s-]/g, '') // remove special chars
          .replace(/\s+/g, '_'); // replace spaces with underscores
          
        const folderName = `Bhatkanti/Events/${safeTitle}`;
        
        const uploadPromises = req.files.map(file => uploadImage(file, folderName));
        const results = await Promise.all(uploadPromises);
        body.images = results.map(res => res.secure_url);
        console.log('Images uploaded successfully:', body.images.length);
      }

      body.createdBy = req.user ? req.user._id : null;

      console.log(`Creating event: "${body.title || 'Untitled'}" by ${req.user ? req.user.name : 'Unknown'}`);
      const event = await Event.create(body);
      
      console.log('Event created successfully with ID:', event._id);
      res.status(201).json({
        status: "OK",
        result: event
      });
    } catch (error) {
      console.error('Add Event Error:', error.message);
      next(error);
    }
  };

  /**
   * Get all events with optional filtering
   */
  getEvents = async (req, res, next) => {
    const { category, popular } = req.query;
    try {
      let filter = {};
      if (category && category !== 'All') {
        filter.category = category;
      }
      if (popular === 'true') {
        filter.isPopular = true;
      }

      const events = await Event.find(filter).sort({ date: 1 });
      res.status(200).json({
        status: "OK",
        results: events
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Get event details by ID
   */
  getEventDetails = async (req, res, next) => {
    const { id } = req.params;
    try {
      const event = await Event.findById(id).populate('createdBy', 'name email');
      if (!event) {
        return res.status(404).json({ error: "Event not found" });
      }
      res.status(200).json({
        status: "OK",
        result: event
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Edit event (Admin/Super-admin only)
   */
  editEvent = async (req, res, next) => {
    const { id } = req.params;
    try {
      console.log('--- Incoming Edit Event Request ---');
      let body = this._parseEventBody(req.body);

      if (req.files && req.files.length > 0) {
        const safeTitle = String(body.title || 'unnamed')
          .trim()
          .replace(/[^\w\s-]/g, '')
          .replace(/\s+/g, '_');
          
        const folderName = `Bhatkanti/Events/${safeTitle}`;
        const uploadPromises = req.files.map(file => uploadImage(file, folderName));
        const results = await Promise.all(uploadPromises);
        body.images = results.map(res => res.secure_url);
      }

      console.log(`Updating event: ${id} ("${body.title || 'no title change'}")`);
      const event = await Event.findByIdAndUpdate(id, body, { new: true, runValidators: true });
      if (!event) {
        return res.status(404).json({ error: "Event not found" });
      }
      res.status(200).json({
        status: "OK",
        result: event
      });
    } catch (error) {
      console.error('Edit Event Error:', error.message);
      next(error);
    }
  };

  /**
   * Delete event (Admin/Super-admin only)
   */
  deleteEvent = async (req, res, next) => {
    const { id } = req.params;
    try {
      const event = await Event.findByIdAndDelete(id);
      if (!event) {
        return res.status(404).json({ error: "Event not found" });
      }
      res.status(200).json({
        status: "OK",
        message: "Event deleted successfully"
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Toggle interest in an event
   */
  toggleInterest = async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user ? req.user._id : null;
    
    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    try {
      const event = await Event.findById(id);
      if (!event) {
        return res.status(404).json({ error: "Event not found" });
      }

      const isCurrentlyInterested = event.interestedUsers.includes(userId);
      let updatedEvent;

      if (isCurrentlyInterested) {
        // Remove interest
        updatedEvent = await Event.findByIdAndUpdate(
          id,
          { 
            $pull: { interestedUsers: userId }, 
            $inc: { interestedCount: -1 } 
          },
          { new: true }
        );
      } else {
        // Add interest
        updatedEvent = await Event.findByIdAndUpdate(
          id,
          { 
            $addToSet: { interestedUsers: userId }, 
            $inc: { interestedCount: 1 } 
          },
          { new: true }
        );
      }

      res.status(200).json({
        status: "OK",
        result: updatedEvent,
        isInterested: !isCurrentlyInterested
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Parse form-data strings into correct types (objects, booleans, numbers)
   */
  _parseEventBody = (body) => {
    if (!body) return {};
    let parsedBody = { ...body };

    // Parse geometry if sent as a JSON string
    if (parsedBody.geometry && typeof parsedBody.geometry === 'string') {
      try {
        parsedBody.geometry = JSON.parse(parsedBody.geometry);
      } catch (e) {
        console.warn('Failed to parse geometry JSON, keeping as string');
      }
    }

    // Parse booleans
    if (typeof parsedBody.isPopular === 'string') {
      parsedBody.isPopular = parsedBody.isPopular === 'true';
    }
    if (typeof parsedBody.isVerified === 'string') {
      parsedBody.isVerified = parsedBody.isVerified === 'true';
    }

    // Parse numbers
    if (typeof parsedBody.interestedCount === 'string') {
      parsedBody.interestedCount = parseInt(parsedBody.interestedCount, 10) || 0;
    }

    return parsedBody;
  };
}

module.exports = new EventsController();
