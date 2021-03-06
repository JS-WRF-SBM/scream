#include "field_layout.hpp"

namespace scream
{

FieldLayout::FieldLayout (const std::initializer_list<FieldTag>& tags)
 : m_rank(tags.size())
 , m_tags(tags)
{
  m_dims.resize(m_rank,-1);
}

FieldLayout::FieldLayout (const std::vector<FieldTag>& tags)
 : m_rank(tags.size())
 , m_tags(tags)
{
  m_dims.resize(m_rank,-1);
}

FieldLayout::FieldLayout (const std::vector<FieldTag>& tags,
                          const std::vector<int>& dims)
 : m_rank(tags.size())
 , m_tags(tags)
{
  m_dims.resize(m_rank,-1);
  set_dimensions(dims);
}

void FieldLayout::set_dimension (const int idim, const int dimension) {
  scream_require_msg(idim>=0 && idim<m_rank, "Error! Index out of bounds.");
  scream_require_msg(dimension>0, "Error! Dimensions must be positive.");
  scream_require_msg(m_dims[idim] == -1, "Error! You cannot reset field dimensions once set.\n");
  m_dims[idim] = dimension;
}

void FieldLayout::set_dimensions (const std::vector<int>& dims) {
  // Check, then set dims
  scream_require_msg(dims.size()==static_cast<size_t>(m_rank),
                     "Error! Input dimensions vector not properly sized.");
  for (int idim=0; idim<m_rank; ++idim) {
    set_dimension(idim,dims[idim]);
  }
}

} // namespace scream
