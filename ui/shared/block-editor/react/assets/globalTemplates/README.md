# Adding A Global Template

You can create global Page and Section templates using the block editor.

## Get the necessary permissions

To create global templates, your user must be in a role that includes
"Block Editor Global Templates - edit" permission.

- Go to your account permissions page (e.g. `/accounts/2/permissions`)
- Add Role
  - The easiest thing to do here is base the role on Teacher and enable
    the permission
- In your course, click on "People" and "+ People"
  - Add your user with the role you created above
- You're ready to go.

## Build your template

- Edit a block page and create your template content
- On the corresponding Page or Section toolbar choose "Save as template".
  (block templates cannot be global templates)
- Give your template a name and description
- Check the "Global template" checkbox
- When you're ready, check the "Published" checkbox
  - If a global template is unpublished, it will only show up for
    users with global block template permissions
  - Note: You can't really edit a global template. You can add it to the
    page, save again, and replace the files in the canvas-lms repo
    (see below).
- Click "Save"

The template and its images will be downloaded to wherever your browser
downloads files.

## Add your template to the canvas-lms repo

If you are not an RCX engineer, send the files to one.

### The template

- Copy the template `.json` file to `ui/shared/block-editor/react/assets/globalTemplates`
- Feel free to rename it to something that makes sense
- Edit `ui/shared/block-editor/react/assets/globalTemplates/index.ts` to import
  the template file and add it to the array arg of `Promsise.resolve`

### The images

- Copy the images files to `public/images/block_editor/templates`
- If there's a filename collision
  - if the images are the same, who cares
  - if the images are different, you'll have to rename the image file
    and edit the template json so the ImageBlock's src property is correct

### Test

- Build canvas-lms
- Create a block page
- If you saved a page template
  - expect it in the "Create Page" list of page templates
  - select it
  - expect to display correctly
- If you saved a section template
  - expect to see your section template in the "Add Content" tray's "Sections" tab
  - add the section to your page
  - expect it to display correctly
